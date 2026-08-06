import '../../../core/networking/api_client.dart';
import '../domain/workout_history_entry.dart';

class WorkoutHistoryRepository {
  WorkoutHistoryRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<WorkoutHistoryEntry>> list({int page = 1, int limit = 20}) async {
    final envelope = await _apiClient.get(
      '/workout-history',
      (data) => data as Map<String, dynamic>,
      query: {'page': page, 'limit': limit},
    );
    final entries = envelope.data!['data'] as List<dynamic>;
    return entries
        .map((e) => WorkoutHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WorkoutHistoryDetail> getById(String id) async {
    final envelope = await _apiClient.get(
      '/workout-history/$id',
      (data) => data as Map<String, dynamic>,
    );
    return WorkoutHistoryDetail.fromJson(envelope.data!);
  }
}
