import '../../../core/networking/api_client.dart';
import '../../rankings/domain/ranking.dart';
import '../domain/sport_match.dart';

/// Thin client for services/api/src/modules/sports — Build Session 8
/// Part 10's confirmed sports matches and Elo-like ratings. Badminton and
/// Table Tennis (Build Session 12 Part 23-24) both exist and share this
/// exact same generic point/set engine — see [listSports].
class SportsRepository {
  SportsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const badmintonCode = 'BADMINTON';
  static const tableTennisCode = 'TABLE_TENNIS';

  Future<List<SportSummary>> listSports() async {
    final envelope = await _apiClient.get(
      '/sports',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map((s) => SportSummary.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<List<SportMatch>> listMine() async {
    final envelope = await _apiClient.get(
      '/sports/matches',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map((m) => SportMatch.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<SportMatch> createMatch({
    required String opponentId,
    String sportCode = badmintonCode,
  }) async {
    final envelope = await _apiClient.post(
      '/sports/matches',
      (data) => data as Map<String, dynamic>,
      data: {'sportCode': sportCode, 'opponentId': opponentId},
    );
    return SportMatch.fromJson(envelope.data!);
  }

  Future<SportMatch> getById(String matchId) async {
    final envelope = await _apiClient.get(
      '/sports/matches/$matchId',
      (data) => data as Map<String, dynamic>,
    );
    return SportMatch.fromJson(envelope.data!);
  }

  Future<SportMatch> accept(String matchId) => _postForMatch('$matchId/accept');

  Future<SportMatch> decline(String matchId) =>
      _postForMatch('$matchId/decline');

  Future<SportMatch> ready(String matchId) => _postForMatch('$matchId/ready');

  Future<SportMatch> start(String matchId) => _postForMatch('$matchId/start');

  Future<SportMatch> proposeScore(
    String matchId, {
    required int proposerScore,
    required int opponentScore,
  }) async {
    final envelope = await _apiClient.post(
      '/sports/matches/$matchId/score',
      (data) => data as Map<String, dynamic>,
      data: {'proposerScore': proposerScore, 'opponentScore': opponentScore},
    );
    return SportMatch.fromJson(envelope.data!);
  }

  Future<SportMatch> confirmScore(String matchId) =>
      _postForMatch('$matchId/score/confirm');

  Future<SportMatch> disputeScore(String matchId, String reason) async {
    final envelope = await _apiClient.post(
      '/sports/matches/$matchId/score/dispute',
      (data) => data as Map<String, dynamic>,
      data: {'reason': reason},
    );
    return SportMatch.fromJson(envelope.data!);
  }

  Future<SportMatch> cancel(String matchId) => _postForMatch('$matchId/cancel');

  Future<SportMatch> voidMatch(String matchId) =>
      _postForMatch('$matchId/void');

  Future<SportRating> getMyRating({String sportCode = badmintonCode}) async {
    final envelope = await _apiClient.get(
      '/sports/$sportCode/rating',
      (data) => data as Map<String, dynamic>,
    );
    return SportRating.fromJson(envelope.data!);
  }

  Future<List<SportLeaderboardEntry>> leaderboard({
    String sportCode = badmintonCode,
    RankingScope scope = RankingScope.global,
  }) async {
    final envelope = await _apiClient.get(
      '/sports/$sportCode/leaderboard',
      (data) => data as List<dynamic>,
      query: {'scope': rankingScopeToJson(scope)},
    );
    return envelope.data!
        .map((e) => SportLeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SportMatch> _postForMatch(String path) async {
    final envelope = await _apiClient.post(
      '/sports/matches/$path',
      (data) => data as Map<String, dynamic>,
    );
    return SportMatch.fromJson(envelope.data!);
  }
}
