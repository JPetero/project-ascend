import '../../../core/networking/api_client.dart';
import '../domain/achievement.dart';

class AchievementRepository {
  AchievementRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Achievement>> list() async {
    final envelope = await _apiClient.get(
      '/achievements',
      (data) => data as List<dynamic>,
    );
    return (envelope.data ?? [])
        .map((a) => Achievement.fromJson(a as Map<String, dynamic>))
        .toList();
  }
}
