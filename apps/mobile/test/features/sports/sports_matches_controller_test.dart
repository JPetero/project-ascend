import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/rankings/domain/ranking.dart';
import 'package:mobile/features/sports/domain/sport_match.dart';
import 'package:mobile/features/sports/presentation/providers/sports_matches_controller.dart';

import '../../helpers/fake_sports_repository.dart';

void main() {
  test('loads matches and rating on construction', () async {
    final repository = FakeSportsRepository(
      matches: [sampleSportMatch(id: 'match-1')],
    );
    final controller = SportsMatchesController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.matches, hasLength(1));
    expect(controller.state.rating, isNotNull);
    expect(controller.state.isLoading, isFalse);
  });

  test('createMatch adds a new challenge and refreshes', () async {
    final repository = FakeSportsRepository();
    final controller = SportsMatchesController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final match = await controller.createMatch('friend-1');

    expect(match, isNotNull);
    expect(controller.state.matches, hasLength(1));
  });

  test(
    'loads the GLOBAL leaderboard on construction (Build Session 13 continuation Part E)',
    () async {
      final repository = FakeSportsRepository(
        leaderboards: {
          RankingScope.global: const [
            SportLeaderboardEntry(
              userId: 'user-1',
              displayName: 'Ada',
              rating: 1520,
              isProvisional: true,
              matchesPlayed: 1,
            ),
          ],
        },
      );
      final controller = SportsMatchesController(repository: repository);
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.leaderboard, hasLength(1));
      expect(controller.state.leaderboardScope, RankingScope.global);
      expect(controller.state.isLeaderboardLoading, isFalse);
    },
  );

  test(
    'selectLeaderboardScope reloads the leaderboard for the new scope',
    () async {
      final repository = FakeSportsRepository(
        leaderboards: {
          RankingScope.friends: const [
            SportLeaderboardEntry(
              userId: 'user-2',
              displayName: 'Bea',
              rating: 1480,
              isProvisional: true,
              matchesPlayed: 1,
            ),
          ],
        },
      );
      final controller = SportsMatchesController(repository: repository);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.leaderboard, isEmpty);

      await controller.selectLeaderboardScope(RankingScope.friends);

      expect(repository.lastLeaderboardScope, RankingScope.friends);
      expect(controller.state.leaderboard, hasLength(1));
      expect(controller.state.leaderboard.single.displayName, 'Bea');
    },
  );

  test(
    'a leaderboard load failure surfaces leaderboardError and clears the list',
    () async {
      final repository = _ThrowingLeaderboardRepository();
      final controller = SportsMatchesController(repository: repository);
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.leaderboard, isEmpty);
      expect(controller.state.leaderboardError, isNotNull);
      expect(controller.state.isLeaderboardLoading, isFalse);
    },
  );
}

class _ThrowingLeaderboardRepository extends FakeSportsRepository {
  @override
  Future<List<SportLeaderboardEntry>> leaderboard({
    String sportCode = 'BADMINTON',
    RankingScope scope = RankingScope.global,
  }) async {
    throw Exception(
      'Opt in to Rankings with a region locality (or narrower) to view this leaderboard.',
    );
  }
}
