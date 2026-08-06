import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/app_database.dart';
import '../../../../core/sync/idempotency_key.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/sync/sync_handler.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/meal_entry_repository.dart';
import '../../domain/food.dart';
import '../../domain/meal_entry.dart';
import '../../domain/meal_type.dart';
import '../../domain/nutrition_macro_math.dart';

const _createEntityType = 'nutrition.meal_entry.create';
const _updateEntityType = 'nutrition.meal_entry.update';
const _deleteEntityType = 'nutrition.meal_entry.delete';
const _copyEntityType = 'nutrition.meal_entry.copy';

String _todayKey() {
  final now = DateTime.now();
  return formatDateOnly(DateTime(now.year, now.month, now.day));
}

MealEntry _fromRow(CachedMealEntry row) {
  return MealEntry(
    id: row.id,
    food: MealEntryFoodRef(
      id: row.foodId,
      name: row.foodName,
      brand: row.foodBrand,
      isEstimated: row.foodIsEstimated,
    ),
    foodServing: row.foodServingId == null
        ? null
        : MealEntryServingRef(
            id: row.foodServingId!,
            label: row.foodServingLabel ?? '',
          ),
    mealType: mealTypeFromJson(row.mealType),
    date: DateTime.parse(row.date),
    quantity: row.quantity,
    calories: row.calories,
    proteinGrams: row.proteinGrams,
    carbGrams: row.carbGrams,
    fatGrams: row.fatGrams,
    fiberGrams: row.fiberGrams,
    notes: row.notes,
  );
}

/// Offline-first: every mutation below writes to Drift and updates [state]
/// before it ever touches the network, then hands the mutation to the
/// shared [SyncEngine] — see packages/docs/build-session-5.md. Reads are
/// always served from the local cache (via a live `watch()` stream), which
/// [_refreshFromServer] keeps fresh in the background; a locally-pending
/// row is never clobbered by a server refresh landing mid-flight.
class MealEntryController extends StateNotifier<AsyncValue<List<MealEntry>>> {
  MealEntryController({
    required MealEntryRepository repository,
    required AppDatabase database,
    required SyncEngine syncEngine,
    required String userId,
  }) : _repository = repository,
       _database = database,
       _syncEngine = syncEngine,
       _userId = userId,
       super(const AsyncValue.loading()) {
    _registerHandlers();
    _subscription = _database.watchMealEntries(_userId, _todayKey()).listen((
      rows,
    ) {
      state = AsyncValue.data(rows.map(_fromRow).toList());
    });
    unawaited(_refreshFromServer());
  }

  final MealEntryRepository _repository;
  final AppDatabase _database;
  final SyncEngine _syncEngine;
  final String _userId;
  StreamSubscription<List<CachedMealEntry>>? _subscription;

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  /// Pull-to-refresh — a best-effort reconciliation with the server on top
  /// of the always-live local cache; see [_refreshFromServer].
  Future<void> refresh() => _refreshFromServer();

  Future<void> _refreshFromServer() async {
    try {
      final serverEntries = await _repository.listForDate(DateTime.now());
      final localRows = await _database.readMealEntriesOnce(
        _userId,
        _todayKey(),
      );
      final serverIds = serverEntries.map((e) => e.id).toSet();

      for (final entry in serverEntries) {
        CachedMealEntry? existing;
        for (final row in localRows) {
          if (row.serverId == entry.id || row.id == entry.id) {
            existing = row;
            break;
          }
        }
        // A row with unsynced local work always wins over a server
        // snapshot that predates it.
        if (existing != null && existing.syncStatus != 'synced') continue;
        await _database.upsertMealEntry(
          _syncedCompanion(existing?.id ?? entry.id, entry),
        );
      }
      for (final row in localRows) {
        if (row.syncStatus == 'synced' &&
            row.serverId != null &&
            !serverIds.contains(row.serverId)) {
          await _database.deleteMealEntryRow(row.id);
        }
      }
    } on AppException {
      // Offline, or the server errored — the cache already emitted via the
      // watch stream is what the UI shows; nothing to reconcile right now.
    }
  }

  CachedMealEntriesCompanion _syncedCompanion(String localId, MealEntry entry) {
    final now = DateTime.now();
    return CachedMealEntriesCompanion.insert(
      id: localId,
      serverId: Value(entry.id),
      userId: _userId,
      foodId: entry.food.id,
      foodName: entry.food.name,
      foodBrand: Value(entry.food.brand),
      foodIsEstimated: Value(entry.food.isEstimated),
      foodServingId: Value(entry.foodServing?.id),
      foodServingLabel: Value(entry.foodServing?.label),
      mealType: mealTypeToJson(entry.mealType),
      date: formatDateOnly(entry.date),
      quantity: entry.quantity,
      calories: entry.calories,
      proteinGrams: entry.proteinGrams,
      carbGrams: entry.carbGrams,
      fatGrams: entry.fatGrams,
      fiberGrams: Value(entry.fiberGrams),
      notes: Value(entry.notes),
      syncStatus: 'synced',
      createdAt: now,
      updatedAt: now,
    );
  }

  void _registerHandlers() {
    _syncEngine.registerHandler(
      _createEntityType,
      FunctionSyncHandler(({required payload, required idempotencyKey}) async {
        try {
          final result = await _repository.addEntry(
            foodId: payload['foodId'] as String,
            foodServingId: payload['foodServingId'] as String?,
            mealType: mealTypeFromJson(payload['mealType'] as String),
            date: DateTime.parse(payload['date'] as String),
            quantity: (payload['quantity'] as num).toDouble(),
            idempotencyKey: idempotencyKey,
          );
          final localRowId = payload['localRowId'] as String;
          await _database.upsertMealEntry(_syncedCompanion(localRowId, result));
          return SyncHandlerResult(entityId: result.id, response: const {});
        } on AppException catch (error) {
          throw SyncFailure(message: error.message, code: error.code);
        }
      }),
    );

    _syncEngine.registerHandler(
      _updateEntityType,
      FunctionSyncHandler(({required payload, required idempotencyKey}) async {
        try {
          final result = await _repository.updateEntry(
            payload['id'] as String,
            foodId: payload['foodId'] as String?,
            foodServingId: payload['foodServingId'] as String?,
            mealType: payload['mealType'] == null
                ? null
                : mealTypeFromJson(payload['mealType'] as String),
            quantity: (payload['quantity'] as num?)?.toDouble(),
            notes: payload['notes'] as String?,
          );
          final localRowId = payload['localRowId'] as String;
          await _database.upsertMealEntry(_syncedCompanion(localRowId, result));
          return SyncHandlerResult(entityId: result.id, response: const {});
        } on AppException catch (error) {
          throw SyncFailure(message: error.message, code: error.code);
        }
      }),
    );

    _syncEngine.registerHandler(
      _deleteEntityType,
      FunctionSyncHandler(({required payload, required idempotencyKey}) async {
        final localRowId = payload['localRowId'] as String;
        try {
          await _repository.deleteEntry(payload['id'] as String);
        } on AppException catch (error) {
          // Another delivery of this same delete already landed — that's
          // success, not a failure to retry.
          if (error.code != 'NOT_FOUND') {
            throw SyncFailure(message: error.message, code: error.code);
          }
        }
        await _database.deleteMealEntryRow(localRowId);
        return const SyncHandlerResult(entityId: null, response: {});
      }),
    );

    _syncEngine.registerHandler(
      _copyEntityType,
      FunctionSyncHandler(({required payload, required idempotencyKey}) async {
        try {
          final created = await _repository.copyEntries(
            sourceDate: DateTime.parse(payload['sourceDate'] as String),
            targetDate: DateTime.parse(payload['targetDate'] as String),
            mealType: payload['mealType'] == null
                ? null
                : mealTypeFromJson(payload['mealType'] as String),
            idempotencyKey: idempotencyKey,
          );
          for (final entry in created) {
            if (formatDateOnly(entry.date) == _todayKey()) {
              await _database.upsertMealEntry(
                _syncedCompanion(entry.id, entry),
              );
            }
          }
          return const SyncHandlerResult(entityId: null, response: {});
        } on AppException catch (error) {
          throw SyncFailure(message: error.message, code: error.code);
        }
      }),
    );
  }

  /// Logs [food] (optionally a specific [serving]) against [mealType] for
  /// today. The calorie/macro snapshot is computed locally — see
  /// `nutrition_macro_math.dart` — so the entry appears with real numbers
  /// immediately, offline or not; the server's authoritative snapshot
  /// overwrites it once the create syncs.
  Future<void> addEntry({
    required Food food,
    FoodServing? serving,
    required MealType mealType,
    required double quantity,
  }) async {
    final localId = generateIdempotencyKey('meal-entry');
    final snapshot = computeMacroSnapshot(
      food: food,
      serving: serving,
      quantity: quantity,
    );
    final now = DateTime.now();
    final date = _todayKey();

    await _database.upsertMealEntry(
      CachedMealEntriesCompanion.insert(
        id: localId,
        userId: _userId,
        foodId: food.id,
        foodName: food.name,
        foodBrand: Value(food.brand),
        foodIsEstimated: Value(food.isEstimated),
        foodServingId: Value(serving?.id),
        foodServingLabel: Value(serving?.label),
        mealType: mealTypeToJson(mealType),
        date: date,
        quantity: quantity,
        calories: snapshot.calories,
        proteinGrams: snapshot.proteinGrams,
        carbGrams: snapshot.carbGrams,
        fatGrams: snapshot.fatGrams,
        fiberGrams: Value(snapshot.fiberGrams),
        syncStatus: 'pendingCreate',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await _syncEngine.enqueue(
      idempotencyKey: localId,
      entityType: _createEntityType,
      operationType: 'CREATE',
      payload: {
        'foodId': food.id,
        'foodServingId': serving?.id,
        'mealType': mealTypeToJson(mealType),
        'date': date,
        'quantity': quantity,
        'localRowId': localId,
      },
    );
  }

  Future<void> updateEntry(
    String id, {
    required Food food,
    FoodServing? serving,
    MealType? mealType,
    double? quantity,
    String? notes,
  }) async {
    final row = await _database.readMealEntry(id);
    if (row == null) return;

    final effectiveMealType = mealType ?? mealTypeFromJson(row.mealType);
    final effectiveQuantity = quantity ?? row.quantity;
    final snapshot = computeMacroSnapshot(
      food: food,
      serving: serving,
      quantity: effectiveQuantity,
    );

    await _database.upsertMealEntry(
      CachedMealEntriesCompanion(
        id: Value(id),
        foodId: Value(food.id),
        foodName: Value(food.name),
        foodBrand: Value(food.brand),
        foodIsEstimated: Value(food.isEstimated),
        foodServingId: Value(serving?.id),
        foodServingLabel: Value(serving?.label),
        mealType: Value(mealTypeToJson(effectiveMealType)),
        quantity: Value(effectiveQuantity),
        calories: Value(snapshot.calories),
        proteinGrams: Value(snapshot.proteinGrams),
        carbGrams: Value(snapshot.carbGrams),
        fatGrams: Value(snapshot.fatGrams),
        fiberGrams: Value(snapshot.fiberGrams),
        notes: Value(notes ?? row.notes),
        syncStatus: Value(
          row.syncStatus == 'pendingCreate' ? 'pendingCreate' : 'pendingUpdate',
        ),
        updatedAt: Value(DateTime.now()),
      ),
    );

    if (row.syncStatus == 'pendingCreate') {
      // Not yet synced — overwrite the still-queued create's own payload
      // (same outbox row, same idempotency key) rather than queueing a
      // second operation, so only one create is ever sent.
      await _syncEngine.enqueue(
        idempotencyKey: id,
        entityType: _createEntityType,
        operationType: 'CREATE',
        payload: {
          'foodId': food.id,
          'foodServingId': serving?.id,
          'mealType': mealTypeToJson(effectiveMealType),
          'date': row.date,
          'quantity': effectiveQuantity,
          'localRowId': id,
        },
      );
      return;
    }

    await _syncEngine.enqueue(
      idempotencyKey: generateIdempotencyKey('meal-entry-update'),
      entityType: _updateEntityType,
      operationType: 'UPDATE',
      payload: {
        'id': row.serverId,
        'localRowId': id,
        'foodId': food.id,
        'foodServingId': serving?.id,
        'mealType': mealTypeToJson(effectiveMealType),
        'quantity': effectiveQuantity,
        'notes': notes ?? row.notes,
      },
    );
  }

  Future<void> deleteEntry(String id) async {
    final row = await _database.readMealEntry(id);
    if (row == null) return;

    if (row.serverId == null) {
      // Never made it to the server — remove locally and cancel the
      // queued create outright instead of sending a delete for something
      // the backend has never heard of.
      await _database.deleteMealEntryRow(id);
      await _syncEngine.discard(id);
      return;
    }

    await _database.upsertMealEntry(
      CachedMealEntriesCompanion(
        id: Value(id),
        syncStatus: const Value('pendingDelete'),
        updatedAt: Value(DateTime.now()),
      ),
    );

    await _syncEngine.enqueue(
      idempotencyKey: generateIdempotencyKey('meal-entry-delete'),
      entityType: _deleteEntityType,
      operationType: 'DELETE',
      payload: {'id': row.serverId, 'localRowId': id},
    );
  }

  /// Copying a day's meals needs the source day's server-computed macro
  /// snapshots, which aren't guaranteed to be cached locally (the source is
  /// often "yesterday", not today) — so unlike every other mutation here,
  /// this follows Workout's network-first-with-fallback pattern (see
  /// `WorkoutPlanEditorService.createPlan`) rather than materializing exact
  /// copied rows offline. `synced` is false if it was queued instead of
  /// landing immediately; `copiedCount` is only meaningful when `synced`.
  Future<({bool synced, int copiedCount})> copyEntries({
    required DateTime sourceDate,
    required DateTime targetDate,
    MealType? mealType,
  }) async {
    final idempotencyKey = generateIdempotencyKey('meal-entry-copy');
    try {
      final created = await _repository.copyEntries(
        sourceDate: sourceDate,
        targetDate: targetDate,
        mealType: mealType,
        idempotencyKey: idempotencyKey,
      );
      for (final entry in created) {
        if (formatDateOnly(entry.date) == _todayKey()) {
          await _database.upsertMealEntry(_syncedCompanion(entry.id, entry));
        }
      }
      return (synced: true, copiedCount: created.length);
    } on AppException catch (error) {
      if (error.code != 'NETWORK_ERROR') rethrow;
      await _syncEngine.enqueue(
        idempotencyKey: idempotencyKey,
        entityType: _copyEntityType,
        operationType: 'CREATE',
        payload: {
          'sourceDate': formatDateOnly(sourceDate),
          'targetDate': formatDateOnly(targetDate),
          'mealType': mealType != null ? mealTypeToJson(mealType) : null,
        },
      );
      return (synced: false, copiedCount: 0);
    }
  }
}

final mealEntryRepositoryProvider = Provider<MealEntryRepository>((ref) {
  return MealEntryRepository(apiClient: ref.watch(apiClientProvider));
});

/// Today's logged meal entries, offline-first — see [MealEntryController].
/// Deliberately not `.autoDispose`, the same way
/// `workoutSessionControllerProvider` isn't: this owns a live Drift
/// subscription and outbox handler registrations that should persist for
/// the app session rather than tearing down and losing in-flight sync work
/// whenever nothing happens to be watching it for a moment.
final todaysMealEntriesProvider =
    StateNotifierProvider<MealEntryController, AsyncValue<List<MealEntry>>>((
      ref,
    ) {
      final userId = ref.watch(
        authControllerProvider.select((s) => s.user?.id),
      );
      return MealEntryController(
        repository: ref.watch(mealEntryRepositoryProvider),
        database: ref.watch(appDatabaseProvider),
        syncEngine: ref.watch(syncEngineProvider),
        userId: userId ?? '',
      );
    });
