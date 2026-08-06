import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/cached_preferences_table.dart';
import 'tables/cached_profile_table.dart';
import 'tables/cached_workout_session_table.dart';
import 'tables/nutrition_tables.dart';
import 'tables/onboarding_draft_table.dart';
import 'tables/outbox_entries_table.dart';
import 'tables/sync_status_table.dart';

part 'app_database.g.dart';

const _syncStatusRowId = 'singleton';
const _onboardingDraftRowId = 'singleton';
const _workoutSessionRowId = 'singleton';

/// Project Ascend's offline foundation.
///
/// Caches the profile and preferences, preserves in-progress onboarding
/// form state, and exposes a simple sync status the UI can surface (e.g.
/// "synced 2 minutes ago"), plus an outbox for queued offline mutations,
/// plus (as of schema version 5) the full offline-first Nutrition cache —
/// see packages/docs/build-session-5.md.
@DriftDatabase(
  tables: [
    CachedProfiles,
    CachedPreferencesTable,
    OnboardingDrafts,
    SyncStatusRows,
    CachedWorkoutSessionRows,
    OutboxEntryRows,
    CachedFoods,
    CachedFoodServings,
    CachedMealEntries,
    CachedSavedMeals,
    CachedWaterEntries,
    CachedMacroTargets,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(cachedWorkoutSessionRows);
      }
      if (from < 3) {
        await m.createTable(outboxEntryRows);
      }
      if (from < 4) {
        // The dashboard fixture table only ever served fabricated
        // sample steps/sleep/recovery data — see
        // packages/docs/product/design-bible.md's "never show
        // fabricated ... values in production mode" rule. Dropped
        // rather than left dead, since nothing reads from it anymore.
        await m.database.customStatement(
          'DROP TABLE IF EXISTS cached_dashboard_fixtures',
        );
      }
      if (from < 5) {
        await m.createTable(cachedFoods);
        await m.createTable(cachedFoodServings);
        await m.createTable(cachedMealEntries);
        await m.createTable(cachedSavedMeals);
        await m.createTable(cachedWaterEntries);
        await m.createTable(cachedMacroTargets);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'ascend.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }

  Future<void> cacheProfile(String userId, Map<String, dynamic> profile) async {
    await into(cachedProfiles).insertOnConflictUpdate(
      CachedProfilesCompanion.insert(
        userId: userId,
        profileJson: jsonEncode(profile),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<Map<String, dynamic>?> readCachedProfile(String userId) async {
    final row = await (select(
      cachedProfiles,
    )..where((t) => t.userId.equals(userId))).getSingleOrNull();
    if (row == null) return null;
    return jsonDecode(row.profileJson) as Map<String, dynamic>;
  }

  Future<void> cachePreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    await into(cachedPreferencesTable).insertOnConflictUpdate(
      CachedPreferencesTableCompanion.insert(
        userId: userId,
        preferencesJson: jsonEncode(preferences),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<Map<String, dynamic>?> readCachedPreferences(String userId) async {
    final row = await (select(
      cachedPreferencesTable,
    )..where((t) => t.userId.equals(userId))).getSingleOrNull();
    if (row == null) return null;
    return jsonDecode(row.preferencesJson) as Map<String, dynamic>;
  }

  Future<void> saveOnboardingDraft(int step, Map<String, dynamic> draft) async {
    await into(onboardingDrafts).insertOnConflictUpdate(
      OnboardingDraftsCompanion.insert(
        id: _onboardingDraftRowId,
        step: step,
        draftJson: jsonEncode(draft),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<(int step, Map<String, dynamic> draft)?> readOnboardingDraft() async {
    final row = await (select(
      onboardingDrafts,
    )..where((t) => t.id.equals(_onboardingDraftRowId))).getSingleOrNull();
    if (row == null) return null;
    return (row.step, jsonDecode(row.draftJson) as Map<String, dynamic>);
  }

  Future<void> clearOnboardingDraft() async {
    await (delete(
      onboardingDrafts,
    )..where((t) => t.id.equals(_onboardingDraftRowId))).go();
  }

  Stream<SyncStatusRow?> watchSyncStatus() {
    return (select(
      syncStatusRows,
    )..where((t) => t.id.equals(_syncStatusRowId))).watchSingleOrNull();
  }

  Future<void> touchSyncStatus() async {
    await into(syncStatusRows).insertOnConflictUpdate(
      SyncStatusRowsCompanion.insert(
        id: _syncStatusRowId,
        lastSyncedAt: Value(DateTime.now()),
        isSyncing: const Value(false),
      ),
    );
  }

  Future<void> cacheWorkoutSession(Map<String, dynamic> session) async {
    await into(cachedWorkoutSessionRows).insertOnConflictUpdate(
      CachedWorkoutSessionRowsCompanion.insert(
        id: _workoutSessionRowId,
        sessionJson: jsonEncode(session),
        updatedAt: DateTime.now(),
      ),
    );
    await touchSyncStatus();
  }

  Future<Map<String, dynamic>?> readCachedWorkoutSession() async {
    final row = await (select(
      cachedWorkoutSessionRows,
    )..where((t) => t.id.equals(_workoutSessionRowId))).getSingleOrNull();
    if (row == null) return null;
    return jsonDecode(row.sessionJson) as Map<String, dynamic>;
  }

  Future<void> clearCachedWorkoutSession() async {
    await (delete(
      cachedWorkoutSessionRows,
    )..where((t) => t.id.equals(_workoutSessionRowId))).go();
  }

  // ---------------------------------------------------------------------
  // Nutrition — offline-first cache (schema version 5). Every method below
  // is scoped by `userId` so a second account signed in on the same device
  // never sees the first account's cached rows even before `clearAll()`
  // runs on sign-out (see `WorkoutSessionController._restore()` for the
  // same defense-in-depth precedent applied to the cached workout
  // session). "Pending delete" rows are tombstones: excluded from every
  // read here, removed for real only once their outbox entry completes.
  // ---------------------------------------------------------------------

  SimpleSelectStatement<$CachedFoodsTable, CachedFood> _cachedFoodsQuery(
    String userId,
  ) {
    return select(cachedFoods)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
  }

  Stream<List<CachedFood>> watchCachedFoods(String userId) {
    return _cachedFoodsQuery(userId).watch();
  }

  /// One-shot read — see the doc comment on [readMealEntriesOnce].
  Future<List<CachedFood>> readCachedFoodsOnce(String userId) {
    return _cachedFoodsQuery(userId).get();
  }

  Future<CachedFood?> readCachedFood(String id) {
    return (select(
      cachedFoods,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsertCachedFood(CachedFoodsCompanion row) async {
    await into(cachedFoods).insertOnConflictUpdate(row);
  }

  Future<void> deleteCachedFood(String id) async {
    await (delete(cachedFoods)..where((t) => t.id.equals(id))).go();
  }

  /// Reassigns a locally-created food's id to the server's real id once its
  /// create sync completes, and follows the reference through to anything
  /// that pointed at the local id — meal entries and saved-meal items
  /// logged against it while it was still only local. This is the
  /// "local-to-server ID reconciliation" the offline Nutrition design
  /// requires: without it, a food created offline and immediately logged
  /// offline would leave those log entries pointing at an id the backend
  /// has never heard of.
  Future<void> reconcileFoodId(String localId, String serverId) async {
    if (localId == serverId) return;
    await transaction(() async {
      final existing = await readCachedFood(localId);
      if (existing != null) {
        await into(cachedFoods).insertOnConflictUpdate(
          existing.toCompanion(true).copyWith(id: Value(serverId)),
        );
        await deleteCachedFood(localId);
      }
      await (update(cachedFoodServings)..where((t) => t.foodId.equals(localId)))
          .write(CachedFoodServingsCompanion(foodId: Value(serverId)));
      await (update(cachedMealEntries)..where((t) => t.foodId.equals(localId)))
          .write(CachedMealEntriesCompanion(foodId: Value(serverId)));
      final savedMeals = await select(cachedSavedMeals).get();
      for (final meal in savedMeals) {
        if (!meal.itemsJson.contains(localId)) continue;
        final items = (jsonDecode(meal.itemsJson) as List<dynamic>)
            .cast<Map<String, dynamic>>();
        var changed = false;
        for (final item in items) {
          if (item['foodId'] == localId) {
            item['foodId'] = serverId;
            changed = true;
          }
        }
        if (changed) {
          await (update(
            cachedSavedMeals,
          )..where((t) => t.id.equals(meal.id))).write(
            CachedSavedMealsCompanion(itemsJson: Value(jsonEncode(items))),
          );
        }
      }
    });
  }

  Future<List<CachedFoodServing>> readCachedFoodServings(String foodId) {
    return (select(
      cachedFoodServings,
    )..where((t) => t.foodId.equals(foodId))).get();
  }

  Future<void> replaceCachedFoodServings(
    String foodId,
    List<CachedFoodServingsCompanion> servings,
  ) async {
    await transaction(() async {
      await (delete(
        cachedFoodServings,
      )..where((t) => t.foodId.equals(foodId))).go();
      for (final serving in servings) {
        await into(cachedFoodServings).insertOnConflictUpdate(serving);
      }
    });
  }

  SimpleSelectStatement<$CachedMealEntriesTable, CachedMealEntry>
  _mealEntriesQuery(String userId, String date) {
    return select(cachedMealEntries)
      ..where(
        (t) =>
            t.userId.equals(userId) &
            t.date.equals(date) &
            t.syncStatus.equals('pendingDelete').not(),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
  }

  Stream<List<CachedMealEntry>> watchMealEntries(String userId, String date) {
    return _mealEntriesQuery(userId, date).watch();
  }

  /// A plain one-shot read — deliberately not `watchMealEntries(...).first`,
  /// which stalls when called alongside an already-active `watch()`
  /// subscription on the same query (a real Drift gotcha hit while building
  /// this: two independent watchers over an identical query don't resolve
  /// their first emission independently).
  Future<List<CachedMealEntry>> readMealEntriesOnce(
    String userId,
    String date,
  ) {
    return _mealEntriesQuery(userId, date).get();
  }

  Future<CachedMealEntry?> readMealEntry(String id) {
    return (select(
      cachedMealEntries,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsertMealEntry(CachedMealEntriesCompanion row) async {
    await into(cachedMealEntries).insertOnConflictUpdate(row);
  }

  Future<void> deleteMealEntryRow(String id) async {
    await (delete(cachedMealEntries)..where((t) => t.id.equals(id))).go();
  }

  SimpleSelectStatement<$CachedSavedMealsTable, CachedSavedMeal>
  _savedMealsQuery(String userId) {
    return select(cachedSavedMeals)
      ..where(
        (t) =>
            t.userId.equals(userId) &
            t.syncStatus.equals('pendingDelete').not(),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
  }

  Stream<List<CachedSavedMeal>> watchSavedMeals(String userId) {
    return _savedMealsQuery(userId).watch();
  }

  /// One-shot read — see the doc comment on [readMealEntriesOnce].
  Future<List<CachedSavedMeal>> readSavedMealsOnce(String userId) {
    return _savedMealsQuery(userId).get();
  }

  Future<CachedSavedMeal?> readSavedMeal(String id) {
    return (select(
      cachedSavedMeals,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsertSavedMeal(CachedSavedMealsCompanion row) async {
    await into(cachedSavedMeals).insertOnConflictUpdate(row);
  }

  Future<void> deleteSavedMealRow(String id) async {
    await (delete(cachedSavedMeals)..where((t) => t.id.equals(id))).go();
  }

  SimpleSelectStatement<$CachedWaterEntriesTable, CachedWaterEntry>
  _waterEntriesQuery(String userId, String date) {
    return select(cachedWaterEntries)
      ..where(
        (t) =>
            t.userId.equals(userId) &
            t.date.equals(date) &
            t.syncStatus.equals('pendingDelete').not(),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.loggedAt)]);
  }

  Stream<List<CachedWaterEntry>> watchWaterEntries(String userId, String date) {
    return _waterEntriesQuery(userId, date).watch();
  }

  /// One-shot read — see the doc comment on [readMealEntriesOnce].
  Future<List<CachedWaterEntry>> readWaterEntriesOnce(
    String userId,
    String date,
  ) {
    return _waterEntriesQuery(userId, date).get();
  }

  Future<CachedWaterEntry?> readWaterEntry(String id) {
    return (select(
      cachedWaterEntries,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsertWaterEntry(CachedWaterEntriesCompanion row) async {
    await into(cachedWaterEntries).insertOnConflictUpdate(row);
  }

  Future<void> deleteWaterEntryRow(String id) async {
    await (delete(cachedWaterEntries)..where((t) => t.id.equals(id))).go();
  }

  SimpleSelectStatement<$CachedMacroTargetsTable, CachedMacroTarget>
  _macroTargetQuery(String userId) {
    return select(cachedMacroTargets)..where((t) => t.userId.equals(userId));
  }

  Stream<CachedMacroTarget?> watchMacroTarget(String userId) {
    return _macroTargetQuery(userId).watchSingleOrNull();
  }

  /// One-shot read — see the doc comment on [readMealEntriesOnce].
  Future<CachedMacroTarget?> readMacroTargetOnce(String userId) {
    return _macroTargetQuery(userId).getSingleOrNull();
  }

  Future<void> upsertMacroTarget(CachedMacroTargetsCompanion row) async {
    await into(cachedMacroTargets).insertOnConflictUpdate(row);
  }

  /// Clears all cached data. Called on sign-out so no data from a
  /// previous account lingers on a shared device.
  Future<void> clearAll() async {
    await Future.wait([
      delete(cachedProfiles).go(),
      delete(cachedPreferencesTable).go(),
      delete(onboardingDrafts).go(),
      delete(syncStatusRows).go(),
      delete(cachedWorkoutSessionRows).go(),
      delete(outboxEntryRows).go(),
      delete(cachedFoods).go(),
      delete(cachedFoodServings).go(),
      delete(cachedMealEntries).go(),
      delete(cachedSavedMeals).go(),
      delete(cachedWaterEntries).go(),
      delete(cachedMacroTargets).go(),
    ]);
  }
}
