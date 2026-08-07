import 'package:mobile/features/rankings/data/rankings_repository.dart';
import 'package:mobile/features/rankings/domain/ranking.dart';

/// In-memory stand-in for [RankingsRepository].
class FakeRankingsRepository implements RankingsRepository {
  FakeRankingsRepository({
    RankingMyStatus? status,
    Map<RankingScope, List<LeaderboardEntry>>? leaderboards,
  }) : status = status ?? const RankingMyStatus(optedIn: false),
       leaderboards = leaderboards ?? {};

  RankingMyStatus status;
  final Map<RankingScope, List<LeaderboardEntry>> leaderboards;

  @override
  Future<RankingMyStatus> getMyStatus() async => status;

  @override
  Future<void> optIn({required RankingScope scope, String? regionLabel}) async {
    status = RankingMyStatus(
      optedIn: true,
      scope: scope,
      regionLabel: regionLabel,
      season: RankingSeason(
        id: 'season-1',
        label: 'August 2026',
        startsAt: DateTime.utc(2026, 8),
        endsAt: DateTime.utc(2026, 9),
      ),
      points: status.points ?? 0,
      activeDays: status.activeDays ?? 0,
    );
  }

  @override
  Future<void> optOut() async {
    status = const RankingMyStatus(optedIn: false);
  }

  @override
  Future<LeaderboardPage> getLeaderboard({
    required RankingScope scope,
    int page = 1,
    int limit = 20,
  }) async {
    if (scope == RankingScope.region && status.scope != RankingScope.region) {
      throw Exception('Opt in with a region to view the regional leaderboard.');
    }
    final entries = leaderboards[scope] ?? const <LeaderboardEntry>[];
    return LeaderboardPage(entries: entries, total: entries.length);
  }
}
