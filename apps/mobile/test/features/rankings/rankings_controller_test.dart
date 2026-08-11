import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/rankings/domain/ranking.dart';
import 'package:mobile/features/rankings/presentation/providers/rankings_controller.dart';

import '../../helpers/fake_rankings_repository.dart';

void main() {
  test('reports opted out by default without fetching a leaderboard', () async {
    final repository = FakeRankingsRepository();
    final controller = RankingsController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.status.optedIn, isFalse);
    expect(controller.state.leaderboard, isEmpty);
  });

  test('opting in loads the leaderboard for the chosen scope', () async {
    final repository = FakeRankingsRepository(
      leaderboards: {
        RankingScope.global: [
          const LeaderboardEntry(
            rank: 1,
            userId: 'user-1',
            points: 4,
            activeDays: 2,
            isViewer: true,
          ),
        ],
      },
    );
    final controller = RankingsController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final ok = await controller.optIn(scope: RankingScope.global);

    expect(ok, isTrue);
    expect(controller.state.status.optedIn, isTrue);
    expect(controller.state.leaderboard, hasLength(1));
  });

  test('opting out clears the leaderboard', () async {
    final repository = FakeRankingsRepository(
      status: const RankingMyStatus(optedIn: true, scope: RankingScope.global),
    );
    final controller = RankingsController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.optOut();

    expect(controller.state.status.optedIn, isFalse);
    expect(controller.state.leaderboard, isEmpty);
  });

  test(
    'switching to REGION without a region opt-in surfaces an error',
    () async {
      final repository = FakeRankingsRepository(
        status: const RankingMyStatus(
          optedIn: true,
          scope: RankingScope.global,
        ),
      );
      final controller = RankingsController(repository: repository);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      await controller.selectScope(RankingScope.region);

      expect(controller.state.error, isNotNull);
      expect(controller.state.leaderboard, isEmpty);
    },
  );

  test('defaults to the OVERALL category', () async {
    final repository = FakeRankingsRepository(
      status: const RankingMyStatus(optedIn: true, scope: RankingScope.global),
    );
    final controller = RankingsController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.selectedCategory, RankingCategory.overall);
  });

  test('selectCategory updates state and reloads the leaderboard', () async {
    final repository = FakeRankingsRepository(
      status: const RankingMyStatus(optedIn: true, scope: RankingScope.global),
      leaderboards: {
        RankingScope.global: [
          const LeaderboardEntry(
            rank: 1,
            userId: 'user-1',
            points: 4,
            activeDays: 2,
            isViewer: true,
            strengthDays: 3,
          ),
        ],
      },
    );
    final controller = RankingsController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.selectCategory(RankingCategory.strength);

    expect(controller.state.selectedCategory, RankingCategory.strength);
    expect(controller.state.leaderboard.single.strengthDays, 3);
  });
}
