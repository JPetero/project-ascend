import '../../../core/networking/api_client.dart';
import '../domain/workout_plan.dart';

class WorkoutPlanRepository {
  WorkoutPlanRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<WorkoutPlan>> list({bool includeArchived = false}) async {
    final envelope = await _apiClient.get(
      '/workout-plans',
      (data) => data as List<dynamic>,
      query: {'includeArchived': '$includeArchived'},
    );
    return (envelope.data ?? [])
        .map((p) => WorkoutPlan.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<WorkoutPlan> getById(String id) async {
    final envelope = await _apiClient.get(
      '/workout-plans/$id',
      (data) => data as Map<String, dynamic>,
    );
    return WorkoutPlan.fromJson(envelope.data!);
  }

  Future<WorkoutPlan> createFromWorkout({
    required String name,
    required String workoutId,
  }) async {
    final envelope = await _apiClient.post(
      '/workout-plans',
      (data) => data as Map<String, dynamic>,
      data: {'name': name, 'workoutId': workoutId},
    );
    return WorkoutPlan.fromJson(envelope.data!);
  }

  /// Creates a from-scratch (or duplicated) plan. `exercises` should already
  /// be ordered — each entry's `order` field is derived from its position
  /// by the caller (see `PlanExerciseDraft.toJson`).
  Future<Map<String, dynamic>> create({
    required String name,
    String? description,
    required List<Map<String, dynamic>> exercises,
    String? idempotencyKey,
  }) async {
    final envelope = await _apiClient.post(
      '/workout-plans',
      (data) => data as Map<String, dynamic>,
      data: {
        'name': name,
        'description': ?description,
        'exercises': exercises,
        'idempotencyKey': ?idempotencyKey,
      },
    );
    return envelope.data!;
  }

  Future<Map<String, dynamic>> update(
    String id, {
    String? name,
    String? description,
    List<Map<String, dynamic>>? exercises,
  }) async {
    final envelope = await _apiClient.patch(
      '/workout-plans/$id',
      (data) => data as Map<String, dynamic>,
      data: {
        'name': ?name,
        'description': ?description,
        'exercises': ?exercises,
      },
    );
    return envelope.data!;
  }

  Future<void> archive(String id) async {
    await _apiClient.post('/workout-plans/$id/archive', (data) => data);
  }

  Future<void> unarchive(String id) async {
    await _apiClient.post('/workout-plans/$id/unarchive', (data) => data);
  }

  Future<void> delete(String id) async {
    await _apiClient.delete('/workout-plans/$id', (data) => data);
  }
}
