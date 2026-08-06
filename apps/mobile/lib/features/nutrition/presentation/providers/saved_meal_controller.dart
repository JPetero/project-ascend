import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/app_database.dart';
import '../../../../core/sync/idempotency_key.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/sync/sync_handler.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../achievements/presentation/providers/achievement_celebration_controller.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/meal_entry_repository.dart' show formatDateOnly;
import '../../data/saved_meal_repository.dart';
import '../../domain/meal_entry.dart';
import '../../domain/meal_type.dart';
import '../../domain/saved_meal.dart';

const _createEntityType = 'nutrition.saved_meal.create';
const _updateEntityType = 'nutrition.saved_meal.update';
const _deleteEntityType = 'nutrition.saved_meal.delete';
const _logEntityType = 'nutrition.saved_meal.log';

/// What a new saved-meal item needs beyond the id/quantity the backend
/// wants — the display fields (name, brand, estimated flag, serving label)
/// so an offline-created saved meal can render immediately without a
/// network round trip.
class SavedMealItemDraft {
  const SavedMealItemDraft({
    required this.foodId,
    required this.foodName,
    this.foodBrand,
    this.foodIsEstimated = true,
    this.foodServingId,
    this.foodServingLabel,
    required this.quantity,
  });

  final String foodId;
  final String foodName;
  final String? foodBrand;
  final bool foodIsEstimated;
  final String? foodServingId;
  final String? foodServingLabel;
  final double quantity;

  Map<String, dynamic> toCacheJson() => {
    'foodId': foodId,
    'foodName': foodName,
    'foodBrand': foodBrand,
    'foodIsEstimated': foodIsEstimated,
    'foodServingId': foodServingId,
    'foodServingLabel': foodServingLabel,
    'quantity': quantity,
  };

  Map<String, dynamic> toApiJson() => {
    'foodId': foodId,
    'foodServingId': foodServingId,
    'quantity': quantity,
  };
}

SavedMeal _fromRow(CachedSavedMeal row) {
  final items = (jsonDecode(row.itemsJson) as List<dynamic>)
      .cast<Map<String, dynamic>>();
  return SavedMeal(
    id: row.id,
    name: row.name,
    createdAt: row.createdAt,
    items: items
        .map(
          (item) => SavedMealItem(
            id: (item['id'] as String?) ?? item['foodId'] as String,
            food: MealEntryFoodRef(
              id: item['foodId'] as String,
              name: item['foodName'] as String,
              brand: item['foodBrand'] as String?,
              isEstimated: item['foodIsEstimated'] as bool? ?? true,
            ),
            foodServing: item['foodServingId'] == null
                ? null
                : MealEntryServingRef(
                    id: item['foodServingId'] as String,
                    label: item['foodServingLabel'] as String? ?? '',
                  ),
            quantity: (item['quantity'] as num).toDouble(),
          ),
        )
        .toList(),
  );
}

/// Offline-first, mirroring [MealEntryController]. Logging a saved meal is
/// the one exception (see [logMeal]): the resulting entries' calories come
/// from a server-side computation this app never fabricates offline, so a
/// queued log doesn't materialize placeholder entries — it appears once
/// the sync completes, exactly like Workout's queued plan creates don't
/// appear in "My Plans" until synced (see `WorkoutPlanEditorService`).
class SavedMealController extends StateNotifier<AsyncValue<List<SavedMeal>>> {
  SavedMealController({
    required SavedMealRepository repository,
    required AppDatabase database,
    required SyncEngine syncEngine,
    required String userId,
    required AchievementCelebrationController celebrationController,
  }) : _repository = repository,
       _database = database,
       _syncEngine = syncEngine,
       _userId = userId,
       _celebrationController = celebrationController,
       super(const AsyncValue.loading()) {
    _registerHandlers();
    _subscription = _database.watchSavedMeals(_userId).listen((rows) {
      state = AsyncValue.data(rows.map(_fromRow).toList());
    });
    unawaited(_refreshFromServer());
  }

  final SavedMealRepository _repository;
  final AppDatabase _database;
  final SyncEngine _syncEngine;
  final String _userId;
  final AchievementCelebrationController _celebrationController;
  StreamSubscription<List<CachedSavedMeal>>? _subscription;

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  Future<void> refresh() => _refreshFromServer();

  Future<void> _refreshFromServer() async {
    try {
      final serverMeals = await _repository.list();
      final localRows = await _database.readSavedMealsOnce(_userId);
      final serverIds = serverMeals.map((m) => m.id).toSet();

      for (final meal in serverMeals) {
        CachedSavedMeal? existing;
        for (final row in localRows) {
          if (row.serverId == meal.id || row.id == meal.id) {
            existing = row;
            break;
          }
        }
        if (existing != null && existing.syncStatus != 'synced') continue;
        await _database.upsertSavedMeal(
          _syncedCompanion(existing?.id ?? meal.id, meal),
        );
      }
      for (final row in localRows) {
        if (row.syncStatus == 'synced' &&
            row.serverId != null &&
            !serverIds.contains(row.serverId)) {
          await _database.deleteSavedMealRow(row.id);
        }
      }
    } on AppException {
      // Offline, or the server errored — the cache already emitted via the
      // watch stream is what the UI shows.
    }
  }

  CachedSavedMealsCompanion _syncedCompanion(String localId, SavedMeal meal) {
    final itemsJson = jsonEncode(
      meal.items
          .map(
            (item) => {
              'id': item.id,
              'foodId': item.food.id,
              'foodName': item.food.name,
              'foodBrand': item.food.brand,
              'foodIsEstimated': item.food.isEstimated,
              'foodServingId': item.foodServing?.id,
              'foodServingLabel': item.foodServing?.label,
              'quantity': item.quantity,
            },
          )
          .toList(),
    );
    return CachedSavedMealsCompanion.insert(
      id: localId,
      serverId: Value(meal.id),
      userId: _userId,
      name: meal.name,
      itemsJson: itemsJson,
      syncStatus: 'synced',
      createdAt: meal.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  void _registerHandlers() {
    _syncEngine.registerHandler(
      _createEntityType,
      FunctionSyncHandler(({required payload, required idempotencyKey}) async {
        try {
          final items = (payload['items'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
          final result = await _repository.create(
            name: payload['name'] as String,
            items: items
                .map(
                  (i) => SavedMealItemInput(
                    foodId: i['foodId'] as String,
                    foodServingId: i['foodServingId'] as String?,
                    quantity: (i['quantity'] as num).toDouble(),
                  ),
                )
                .toList(),
            idempotencyKey: idempotencyKey,
          );
          final localRowId = payload['localRowId'] as String;
          await _database.upsertSavedMeal(_syncedCompanion(localRowId, result));
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
          final items = payload['items'] == null
              ? null
              : (payload['items'] as List<dynamic>)
                    .cast<Map<String, dynamic>>()
                    .map(
                      (i) => SavedMealItemInput(
                        foodId: i['foodId'] as String,
                        foodServingId: i['foodServingId'] as String?,
                        quantity: (i['quantity'] as num).toDouble(),
                      ),
                    )
                    .toList();
          final result = await _repository.update(
            id: payload['id'] as String,
            name: payload['name'] as String?,
            items: items,
          );
          final localRowId = payload['localRowId'] as String;
          await _database.upsertSavedMeal(_syncedCompanion(localRowId, result));
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
          await _repository.delete(payload['id'] as String);
        } on AppException catch (error) {
          if (error.code != 'NOT_FOUND') {
            throw SyncFailure(message: error.message, code: error.code);
          }
        }
        await _database.deleteSavedMealRow(localRowId);
        return const SyncHandlerResult(entityId: null, response: {});
      }),
    );

    _syncEngine.registerHandler(
      _logEntityType,
      FunctionSyncHandler(({required payload, required idempotencyKey}) async {
        try {
          final result = await _repository.logMeal(
            id: payload['id'] as String,
            mealType: mealTypeFromJson(payload['mealType'] as String),
            date: DateTime.parse(payload['date'] as String),
            idempotencyKey: idempotencyKey,
          );
          final today = formatDateOnly(DateTime.now());
          for (final entry in result.entries) {
            if (formatDateOnly(entry.date) != today) continue;
            await _database.upsertMealEntry(
              CachedMealEntriesCompanion.insert(
                id: entry.id,
                serverId: Value(entry.id),
                userId: _userId,
                foodId: entry.food.id,
                foodName: entry.food.name,
                foodBrand: Value(entry.food.brand),
                foodIsEstimated: Value(entry.food.isEstimated),
                foodServingId: Value(entry.foodServing?.id),
                foodServingLabel: Value(entry.foodServing?.label),
                mealType: mealTypeToJson(entry.mealType),
                date: today,
                quantity: entry.quantity,
                calories: entry.calories,
                proteinGrams: entry.proteinGrams,
                carbGrams: entry.carbGrams,
                fatGrams: entry.fatGrams,
                fiberGrams: Value(entry.fiberGrams),
                syncStatus: 'synced',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
          }
          await _celebrationController.enqueue(result.newAchievements);
          return const SyncHandlerResult(entityId: null, response: {});
        } on AppException catch (error) {
          throw SyncFailure(message: error.message, code: error.code);
        }
      }),
    );
  }

  Future<void> create({
    required String name,
    required List<SavedMealItemDraft> items,
  }) async {
    final localId = generateIdempotencyKey('saved-meal');
    final now = DateTime.now();
    final itemsJson = jsonEncode(items.map((i) => i.toCacheJson()).toList());

    await _database.upsertSavedMeal(
      CachedSavedMealsCompanion.insert(
        id: localId,
        userId: _userId,
        name: name,
        itemsJson: itemsJson,
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
        'name': name,
        'items': items.map((i) => i.toApiJson()).toList(),
        'localRowId': localId,
      },
    );
  }

  Future<void> update(
    String id, {
    String? name,
    List<SavedMealItemDraft>? items,
  }) async {
    final row = await _database.readSavedMeal(id);
    if (row == null) return;

    await _database.upsertSavedMeal(
      CachedSavedMealsCompanion(
        id: Value(id),
        name: Value(name ?? row.name),
        itemsJson: Value(
          items == null
              ? row.itemsJson
              : jsonEncode(items.map((i) => i.toCacheJson()).toList()),
        ),
        syncStatus: Value(
          row.syncStatus == 'pendingCreate' ? 'pendingCreate' : 'pendingUpdate',
        ),
        updatedAt: Value(DateTime.now()),
      ),
    );

    if (row.syncStatus == 'pendingCreate') {
      final effectiveItems =
          items ??
          (jsonDecode(row.itemsJson) as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map(
                (i) => {
                  'foodId': i['foodId'],
                  'foodServingId': i['foodServingId'],
                  'quantity': i['quantity'],
                },
              )
              .toList();
      await _syncEngine.enqueue(
        idempotencyKey: id,
        entityType: _createEntityType,
        operationType: 'CREATE',
        payload: {
          'name': name ?? row.name,
          'items': effectiveItems,
          'localRowId': id,
        },
      );
      return;
    }

    await _syncEngine.enqueue(
      idempotencyKey: generateIdempotencyKey('saved-meal-update'),
      entityType: _updateEntityType,
      operationType: 'UPDATE',
      payload: {
        'id': row.serverId,
        'localRowId': id,
        'name': name,
        'items': items?.map((i) => i.toApiJson()).toList(),
      },
    );
  }

  Future<void> delete(String id) async {
    final row = await _database.readSavedMeal(id);
    if (row == null) return;

    if (row.serverId == null) {
      await _database.deleteSavedMealRow(id);
      await _syncEngine.discard(id);
      return;
    }

    await _database.upsertSavedMeal(
      CachedSavedMealsCompanion(
        id: Value(id),
        syncStatus: const Value('pendingDelete'),
        updatedAt: Value(DateTime.now()),
      ),
    );

    await _syncEngine.enqueue(
      idempotencyKey: generateIdempotencyKey('saved-meal-delete'),
      entityType: _deleteEntityType,
      operationType: 'DELETE',
      payload: {'id': row.serverId, 'localRowId': id},
    );
  }

  /// Queues logging a saved meal. Never fabricates the resulting entries'
  /// macros offline — see the class doc comment — so this always queues
  /// through the outbox even when online, for one consistent code path;
  /// [SyncEngine.enqueue] still attempts an immediate drain, so on a
  /// working connection it resolves within the same moment.
  Future<void> logMeal({
    required String id,
    required MealType mealType,
    required DateTime date,
  }) async {
    await _syncEngine.enqueue(
      idempotencyKey: generateIdempotencyKey('saved-meal-log'),
      entityType: _logEntityType,
      operationType: 'CREATE',
      payload: {
        'id': id,
        'mealType': mealTypeToJson(mealType),
        'date': formatDateOnly(date),
      },
    );
  }
}

final savedMealRepositoryProvider = Provider<SavedMealRepository>((ref) {
  return SavedMealRepository(apiClient: ref.watch(apiClientProvider));
});

/// The user's saved meals, offline-first — see [SavedMealController]. Not
/// `.autoDispose` — see the doc comment on `todaysMealEntriesProvider`.
final savedMealsProvider =
    StateNotifierProvider<SavedMealController, AsyncValue<List<SavedMeal>>>((
      ref,
    ) {
      final userId = ref.watch(
        authControllerProvider.select((s) => s.user?.id),
      );
      return SavedMealController(
        repository: ref.watch(savedMealRepositoryProvider),
        database: ref.watch(appDatabaseProvider),
        syncEngine: ref.watch(syncEngineProvider),
        userId: userId ?? '',
        celebrationController: ref.watch(
          achievementCelebrationControllerProvider.notifier,
        ),
      );
    });
