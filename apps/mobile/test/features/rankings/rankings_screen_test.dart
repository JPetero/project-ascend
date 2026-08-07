import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/rankings/domain/ranking.dart';
import 'package:mobile/features/rankings/presentation/screens/rankings_screen.dart';

import '../../helpers/fake_rankings_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows an honest opt-in prompt when not opted in', (
    tester,
  ) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RankingsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Rankings are opt-in'), findsOneWidget);
  });

  testWidgets('shows the leaderboard once opted in', (tester) async {
    final repository = FakeRankingsRepository(
      status: const RankingMyStatus(optedIn: true, scope: RankingScope.global),
      leaderboards: {
        RankingScope.global: [
          const LeaderboardEntry(
            rank: 1,
            userId: 'user-1',
            displayName: 'Ada',
            points: 4,
            activeDays: 2,
            isViewer: true,
          ),
        ],
      },
    );
    final container = await createTestContainer(
      signedIn: true,
      rankingsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RankingsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.textContaining('Ada'), findsOneWidget);
    expect(find.textContaining('4 pts'), findsOneWidget);
  });
}
