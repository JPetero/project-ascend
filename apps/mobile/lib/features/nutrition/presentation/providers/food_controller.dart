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
import '../../data/food_repository.dart';
import '../../domain/food.dart';

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepository(apiClient: ref.watch(apiClientProvider));
});

const _createEntityType = 'nutrition.food.create';
const _updateEntityType = 'nutrition.food.update';
const _archiveEntityType = 'nutrition.food.archive';

/// Offline-first custom-food create/edit/archive — see
/// packages/docs/build-session-5.md. Food *search* stays online-only
/// (`FoodRepository.search`); this only owns the write path for a user's
/// own custom foods, mirroring [MealEntryController]'s design.
class CustomFoodController {
  CustomFoodController({
    required FoodRepository repository,
    required AppDatabase database,
    required SyncEngine syncEngine,
    required String userId,
  }) : _repository = repository,
       _database = database,
       _syncEngine = syncEngine,
       _userId = userId {
    _registerHandlers();
  }

  final FoodRepository _repository;
  final AppDatabase _database;
  final SyncEngine _syncEngine;
  final String _userId;

  CachedFoodsCompanion _syncedCompanion(String localId, Food food) {
    return CachedFoodsCompanion.insert(
      id: localId,
      userId: _userId,
      name: food.name,
      alternateName: Value(food.alternateName),
      brand: Value(food.brand),
      sourceType: 'USER',
      isOwnedByCurrentUser: const Value(true),
      servingDescription: food.servingDescription,
      servingGrams: Value(food.servingGrams),
      caloriesPerServing: food.caloriesPerServing,
      proteinGramsPerServing: food.proteinGramsPerServing,
      carbGramsPerServing: food.carbGramsPerServing,
      fatGramsPerServing: food.fatGramsPerServing,
      fiberGramsPerServing: Value(food.fiberGramsPerServing),
      sodiumMgPerServing: Value(food.sodiumMgPerServing),
      isEstimated: Value(food.isEstimated),
      syncStatus: const Value('synced'),
      updatedAt: DateTime.now(),
    );
  }

  void _registerHandlers() {
    _syncEngine.registerHandler(
      _createEntityType,
      FunctionSyncHandler(({required payload, required idempotencyKey}) async {
        try {
          final result = await _repository.createCustom(
            _inputFromPayload(payload),
            idempotencyKey: idempotencyKey,
          );
          final localRowId = payload['localRowId'] as String;
          await _database.upsertCachedFood(
            _syncedCompanion(localRowId, result),
          );
          await _database.reconcileFoodId(localRowId, result.id);
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
          final result = await _repository.updateCustom(
            payload['id'] as String,
            _inputFromPayload(payload),
          );
          final localRowId = payload['localRowId'] as String;
          await _database.upsertCachedFood(
            _syncedCompanion(localRowId, result),
          );
          return SyncHandlerResult(entityId: result.id, response: const {});
        } on AppException catch (error) {
          throw SyncFailure(message: error.message, code: error.code);
        }
      }),
    );

    _syncEngine.registerHandler(
      _archiveEntityType,
      FunctionSyncHandler(({required payload, required idempotencyKey}) async {
        try {
          final result = await _repository.archiveCustom(
            payload['id'] as String,
          );
          final localRowId = payload['localRowId'] as String;
          await _database.upsertCachedFood(
            _syncedCompanion(localRowId, result),
          );
          return SyncHandlerResult(entityId: result.id, response: const {});
        } on AppException catch (error) {
          throw SyncFailure(message: error.message, code: error.code);
        }
      }),
    );
  }

  CustomFoodInput _inputFromPayload(Map<String, dynamic> payload) {
    return CustomFoodInput(
      name: payload['name'] as String,
      servingDescription: payload['servingDescription'] as String,
      caloriesPerServing: (payload['caloriesPerServing'] as num).toDouble(),
      proteinGramsPerServing: (payload['proteinGramsPerServing'] as num)
          .toDouble(),
      carbGramsPerServing: (payload['carbGramsPerServing'] as num).toDouble(),
      fatGramsPerServing: (payload['fatGramsPerServing'] as num).toDouble(),
      fiberGramsPerServing: (payload['fiberGramsPerServing'] as num?)
          ?.toDouble(),
      sodiumMgPerServing: (payload['sodiumMgPerServing'] as num?)?.toDouble(),
    );
  }

  /// Returns the offline-visible [Food] immediately (local id until synced).
  Future<Food> create(CustomFoodInput input) async {
    final localId = generateIdempotencyKey('food');
    final food = Food(
      id: localId,
      name: input.name,
      isOwnedByCurrentUser: true,
      servingDescription: input.servingDescription,
      caloriesPerServing: input.caloriesPerServing,
      proteinGramsPerServing: input.proteinGramsPerServing,
      carbGramsPerServing: input.carbGramsPerServing,
      fatGramsPerServing: input.fatGramsPerServing,
      fiberGramsPerServing: input.fiberGramsPerServing,
      sodiumMgPerServing: input.sodiumMgPerServing,
      isEstimated: true,
    );

    await _database.upsertCachedFood(
      CachedFoodsCompanion.insert(
        id: localId,
        userId: _userId,
        name: input.name,
        sourceType: 'USER',
        isOwnedByCurrentUser: const Value(true),
        servingDescription: input.servingDescription,
        caloriesPerServing: input.caloriesPerServing,
        proteinGramsPerServing: input.proteinGramsPerServing,
        carbGramsPerServing: input.carbGramsPerServing,
        fatGramsPerServing: input.fatGramsPerServing,
        fiberGramsPerServing: Value(input.fiberGramsPerServing),
        sodiumMgPerServing: Value(input.sodiumMgPerServing),
        isEstimated: const Value(true),
        syncStatus: const Value('pendingCreate'),
        updatedAt: DateTime.now(),
      ),
    );

    await _syncEngine.enqueue(
      idempotencyKey: localId,
      entityType: _createEntityType,
      operationType: 'CREATE',
      payload: {...input.toJson(), 'localRowId': localId},
    );

    return food;
  }

  Future<void> archive(String id) async {
    final row = await _database.readCachedFood(id);
    if (row == null) return;

    await _database.upsertCachedFood(
      CachedFoodsCompanion(
        id: Value(id),
        archivedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );

    if (row.syncStatus != 'synced') {
      // Not confirmed on the server yet — the still-queued create/update
      // will land eventually; nothing more to send for an archive of a
      // food the backend doesn't know about.
      return;
    }

    await _syncEngine.enqueue(
      idempotencyKey: generateIdempotencyKey('food-archive'),
      entityType: _archiveEntityType,
      operationType: 'UPDATE',
      payload: {'id': id, 'localRowId': id},
    );
  }
}

final customFoodControllerProvider = Provider<CustomFoodController>((ref) {
  final userId = ref.watch(authControllerProvider.select((s) => s.user?.id));
  return CustomFoodController(
    repository: ref.watch(foodRepositoryProvider),
    database: ref.watch(appDatabaseProvider),
    syncEngine: ref.watch(syncEngineProvider),
    userId: userId ?? '',
  );
});
