import '../../../core/networking/api_client.dart';
import '../domain/deload_recommendation.dart';

class DeloadRepository {
  DeloadRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Null when no recommendation is currently active — the common case.
  Future<DeloadRecommendation?> getActive() async {
    final envelope = await _apiClient.get(
      '/deload/recommendation',
      (data) => data as Map<String, dynamic>?,
    );
    final data = envelope.data;
    if (data == null) return null;
    return DeloadRecommendation.fromJson(data);
  }

  Future<void> dismiss(String id) async {
    await _apiClient.post(
      '/deload/recommendations/$id/dismiss',
      (data) => data,
    );
  }

  Future<void> postpone(String id, {int days = 7}) async {
    await _apiClient.post(
      '/deload/recommendations/$id/postpone',
      (data) => data,
      data: {'days': days},
    );
  }
}
