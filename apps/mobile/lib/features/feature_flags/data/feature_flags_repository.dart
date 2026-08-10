import '../../../core/networking/api_client.dart';

class FeatureFlagsRepository {
  FeatureFlagsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, bool>> resolve() async {
    final envelope = await _apiClient.get(
      '/feature-flags',
      (data) => data as Map<String, dynamic>,
    );
    final json = envelope.data ?? <String, dynamic>{};
    return json.map((key, value) => MapEntry(key, value as bool));
  }
}
