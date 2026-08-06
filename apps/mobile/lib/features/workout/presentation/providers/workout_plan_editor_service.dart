import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/sync/idempotency_key.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/sync/sync_handler.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../data/workout_plan_repository.dart';
import 'workout_plan_controller.dart';

const _createEntityType = 'workout.plan.create';
const _updateEntityType = 'workout.plan.update';

/// Saving a plan (create or edit), local-first the same way the rest of the
/// Workout Engine is: try the network call now; if it fails for a
/// transient reason, hand it to the generic [SyncEngine] instead of losing
/// it, using an idempotency key so a later retry (or an app restart before
/// the first attempt lands) can never create two plans for one save.
///
/// Deliberately not a local plan *cache* — a queued create/edit isn't
/// reflected in "My Plans" until it syncs. That's a real, documented
/// scope cut (see build-session-2.md): the durability and duplicate-safety
/// guarantees are real, but there's no offline list view of not-yet-synced
/// plans in this pass.
class WorkoutPlanEditorService {
  WorkoutPlanEditorService({
    required WorkoutPlanRepository repository,
    required SyncEngine syncEngine,
  }) : _repository = repository,
       _syncEngine = syncEngine {
    _syncEngine.registerHandler(
      _createEntityType,
      FunctionSyncHandler(({required payload, required idempotencyKey}) async {
        final result = await _repository.create(
          name: payload['name'] as String,
          description: payload['description'] as String?,
          exercises: (payload['exercises'] as List<dynamic>)
              .cast<Map<String, dynamic>>(),
          idempotencyKey: idempotencyKey,
        );
        return SyncHandlerResult(
          entityId: result['id'] as String?,
          response: result,
        );
      }),
    );
    _syncEngine.registerHandler(
      _updateEntityType,
      FunctionSyncHandler(({required payload, required idempotencyKey}) async {
        final result = await _repository.update(
          payload['id'] as String,
          name: payload['name'] as String?,
          description: payload['description'] as String?,
          exercises: payload['exercises'] == null
              ? null
              : (payload['exercises'] as List<dynamic>)
                    .cast<Map<String, dynamic>>(),
        );
        return SyncHandlerResult(
          entityId: result['id'] as String?,
          response: result,
        );
      }),
    );
  }

  final WorkoutPlanRepository _repository;
  final SyncEngine _syncEngine;

  /// Returns true if the save landed immediately, false if it was queued
  /// for later sync (still durably recorded — never data loss, and the
  /// caller should tell the user their edit is queued, not that it's lost).
  Future<bool> createPlan({
    required String name,
    String? description,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final idempotencyKey = generateIdempotencyKey('plan-create');
    try {
      await _repository.create(
        name: name,
        description: description,
        exercises: exercises,
        idempotencyKey: idempotencyKey,
      );
      return true;
    } on AppException catch (error) {
      if (error.code != 'NETWORK_ERROR') rethrow;
      await _syncEngine.enqueue(
        idempotencyKey: idempotencyKey,
        entityType: _createEntityType,
        operationType: 'CREATE',
        payload: {
          'name': name,
          'description': description,
          'exercises': exercises,
        },
      );
      return false;
    }
  }

  Future<bool> updatePlan({
    required String id,
    String? name,
    String? description,
    List<Map<String, dynamic>>? exercises,
  }) async {
    final idempotencyKey = generateIdempotencyKey('plan-update');
    try {
      await _repository.update(
        id,
        name: name,
        description: description,
        exercises: exercises,
      );
      return true;
    } on AppException catch (error) {
      if (error.code != 'NETWORK_ERROR') rethrow;
      await _syncEngine.enqueue(
        idempotencyKey: idempotencyKey,
        entityType: _updateEntityType,
        operationType: 'UPDATE',
        payload: {
          'id': id,
          'name': name,
          'description': description,
          'exercises': exercises,
        },
      );
      return false;
    }
  }
}

final workoutPlanEditorServiceProvider = Provider<WorkoutPlanEditorService>((
  ref,
) {
  return WorkoutPlanEditorService(
    repository: ref.watch(workoutPlanRepositoryProvider),
    syncEngine: ref.watch(syncEngineProvider),
  );
});
