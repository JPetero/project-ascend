import '../../../core/networking/api_client.dart';
import '../domain/ranking.dart';

/// Thin client for services/api/src/modules/rankings — opt-in status and
/// the FRIENDS/LOCAL/CITY/REGION/NATIONAL/GLOBAL leaderboards. See
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

  Future<void> optIn({
    required RankingScope scope,
    String? localityCountry,
    String? localityRegion,
    String? localityCity,
    String? localityArea,
  }) async {
    await _apiClient.put(
      '/rankings/opt-in',
      (_) => null,
      data: {
        'scope': rankingScopeToJson(scope),
        'localityCountry': ?localityCountry,
        'localityRegion': ?localityRegion,
        'localityCity': ?localityCity,
        'localityArea': ?localityArea,
      },
    );
  }

  Future<void> optOut() async {
    await _apiClient.delete('/rankings/opt-in', (_) => null);
  }

  Future<LeaderboardPage> getLeaderboard({
    required RankingScope scope,
    RankingCategory category = RankingCategory.overall,
    int page = 1,
    int limit = 20,
  }) async {
    final envelope = await _apiClient.get(
      '/rankings/leaderboard',
      (data) => data as Map<String, dynamic>,
      query: {
        'scope': rankingScopeToJson(scope),
        'category': rankingCategoryToJson(category),
        'page': page,
        'limit': limit,
      },
    );
    return LeaderboardPage.fromJson(envelope.data!);
  }
}
