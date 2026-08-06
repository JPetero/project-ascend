import '../../../core/networking/api_client.dart';
import '../domain/workout.dart';

class WorkoutCatalogRepository {
  WorkoutCatalogRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Workout>> list({String? categorySlug}) async {
    final envelope = await _apiClient.get(
      '/workouts',
      (data) => data as List<dynamic>,
      query: {'categorySlug': ?categorySlug},
    );
    return (envelope.data ?? [])
        .map((w) => Workout.fromJson(w as Map<String, dynamic>))
        .toList();
  }

  Future<Workout> getById(String id) async {
    final envelope = await _apiClient.get(
      '/workouts/$id',
      (data) => data as Map<String, dynamic>,
    );
    return Workout.fromJson(envelope.data!);
  }
}
