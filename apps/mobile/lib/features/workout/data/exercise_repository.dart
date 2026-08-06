import '../../../core/networking/api_client.dart';
import '../domain/exercise.dart';
import '../domain/progression_suggestion.dart';

class ExerciseRepository {
  ExerciseRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Exercise>> list({
    String? categorySlug,
    String? muscleSlug,
    String? equipmentSlug,
    String? search,
  }) async {
    final envelope = await _apiClient.get(
      '/exercises',
      (data) => data as List<dynamic>,
      query: {
        'categorySlug': ?categorySlug,
        'muscleSlug': ?muscleSlug,
        'equipmentSlug': ?equipmentSlug,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return (envelope.data ?? [])
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Exercise> getById(String id) async {
    final envelope = await _apiClient.get(
      '/exercises/$id',
      (data) => data as Map<String, dynamic>,
    );
    return Exercise.fromJson(envelope.data!);
  }

  Future<ProgressionSuggestion> getProgression(String exerciseId) async {
    final envelope = await _apiClient.get(
      '/exercises/$exerciseId/progression',
      (data) => data as Map<String, dynamic>,
    );
    return ProgressionSuggestion.fromJson(envelope.data!);
  }
}
