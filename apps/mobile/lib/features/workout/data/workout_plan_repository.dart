import '../../../core/networking/api_client.dart';
import '../domain/workout_plan.dart';

class WorkoutPlanRepository {
  WorkoutPlanRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<WorkoutPlan>> list() async {
    final envelope = await _apiClient.get(
      '/workout-plans',
      (data) => data as List<dynamic>,
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

  Future<void> delete(String id) async {
    await _apiClient.delete('/workout-plans/$id', (data) => data);
  }
}
