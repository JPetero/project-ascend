import '../../../core/networking/api_client.dart';
import '../domain/ranking.dart';

/// Thin client for services/api/src/modules/rankings — opt-in status and
/// the FRIENDS/REGION/GLOBAL leaderboards. See
/// packages/docs/product/user-scenario-bible.md Scenario 16a.
class RankingsRepository {
  RankingsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<RankingMyStatus> getMyStatus() async {
    final envelope = await _apiClient.get(
      '/rankings/me',
      (data) => data as Map<String, dynamic>,
    );
    return RankingMyStatus.fromJson(envelope.data!);
  }

  Future<void> optIn({required RankingScope scope, String? regionLabel}) async {
    await _apiClient.put(
      '/rankings/opt-in',
      (_) => null,
      data: {'scope': rankingScopeToJson(scope), 'regionLabel': ?regionLabel},
    );
  }

  Future<void> optOut() async {
    await _apiClient.delete('/rankings/opt-in', (_) => null);
  }

  Future<LeaderboardPage> getLeaderboard({
    required RankingScope scope,
    int page = 1,
    int limit = 20,
  }) async {
    final envelope = await _apiClient.get(
      '/rankings/leaderboard',
      (data) => data as Map<String, dynamic>,
      query: {'scope': rankingScopeToJson(scope), 'page': page, 'limit': limit},
    );
    return LeaderboardPage.fromJson(envelope.data!);
  }
}
