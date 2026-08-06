import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/cached_dashboard_table.dart';
import 'tables/cached_preferences_table.dart';
import 'tables/cached_profile_table.dart';
import 'tables/cached_workout_session_table.dart';
import 'tables/onboarding_draft_table.dart';
import 'tables/sync_status_table.dart';

part 'app_database.g.dart';

const _syncStatusRowId = 'singleton';
const _onboardingDraftRowId = 'singleton';
const _workoutSessionRowId = 'singleton';

/// Project Ascend's offline foundation.
///
/// Sprint 1 scope: cache the profile, preferences, and dashboard fixture,
/// preserve in-progress onboarding form state, and expose a simple sync
/// status the UI can surface (e.g. "synced 2 minutes ago").
///
/// Deliberately out of scope for this sprint (see
/// packages/docs/architecture.md for the planned strategy): local-first
/// writes for workout/meal logs, an outbox table for queued mutations,
/// idempotency keys, and server-side reconciliation. Those require a
/// conflict-resolution design that a single-cache scaffold doesn't need yet.
@DriftDatabase(
  tables: [
    CachedProfiles,
    CachedPreferencesTable,
    CachedDashboardFixtures,
    OnboardingDrafts,
    SyncStatusRows,
    CachedWorkoutSessionRows,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(cachedWorkoutSessionRows);
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

  Future<void> cacheDashboard(
    String userId,
    Map<String, dynamic> dashboard,
  ) async {
    await into(cachedDashboardFixtures).insertOnConflictUpdate(
      CachedDashboardFixturesCompanion.insert(
        userId: userId,
        dashboardJson: jsonEncode(dashboard),
        updatedAt: DateTime.now(),
      ),
    );
    await _touchSyncStatus();
  }

  Future<Map<String, dynamic>?> readCachedDashboard(String userId) async {
    final row = await (select(
      cachedDashboardFixtures,
    )..where((t) => t.userId.equals(userId))).getSingleOrNull();
    if (row == null) return null;
    return jsonDecode(row.dashboardJson) as Map<String, dynamic>;
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

  Future<void> _touchSyncStatus() async {
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

  /// Clears all cached data. Called on sign-out so no data from a
  /// previous account lingers on a shared device.
  Future<void> clearAll() async {
    await Future.wait([
      delete(cachedProfiles).go(),
      delete(cachedPreferencesTable).go(),
      delete(cachedDashboardFixtures).go(),
      delete(onboardingDrafts).go(),
      delete(syncStatusRows).go(),
      delete(cachedWorkoutSessionRows).go(),
    ]);
  }
}
