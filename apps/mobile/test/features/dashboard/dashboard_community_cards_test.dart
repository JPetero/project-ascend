import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:mobile/features/rankings/domain/ranking.dart';

import '../../helpers/fake_friends_repository.dart';
import '../../helpers/fake_messages_repository.dart';
import '../../helpers/fake_rankings_repository.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  // The Community section sits below the fold in Dashboard's ListView,
  // which (like any Sliver-backed scroll view) only builds Elements near
  // the viewport — mirrors sign_out_test.dart's identical need to scroll
  // before its own below-the-fold assertion.
  Future<void> scrollUntilFound(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }

  group('Dashboard Community section — Build Session 9 Part 1', () {
    testWidgets(
      'shows an honest opt-in prompt for Rankings, not a fabricated rank',
      (tester) async {
        final container = await createTestContainer(signedIn: true);
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: DashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();
        await scrollUntilFound(tester, find.text('Rankings'));

        expect(find.text('Rankings'), findsOneWidget);
        expect(
          find.textContaining('Opt in to see where you rank'),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows a real rank once opted in with a leaderboard entry', (
      tester,
    ) async {
      final container = await createTestContainer(
        signedIn: true,
        rankingsRepository: FakeRankingsRepository(
          status: const RankingMyStatus(
            optedIn: true,
            scope: RankingScope.global,
            points: 12,
            activeDays: 6,
          ),
          leaderboards: {
            RankingScope.global: const [
              LeaderboardEntry(
                rank: 3,
                userId: 'me',
                points: 12,
                activeDays: 6,
                isViewer: true,
              ),
            ],
          },
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await scrollUntilFound(tester, find.textContaining('Rank #3'));

      expect(find.textContaining('Rank #3'), findsOneWidget);
    });

    testWidgets('shows real friend count and pending request count', (
      tester,
    ) async {
      final container = await createTestContainer(
        signedIn: true,
        friendsRepository: FakeFriendsRepository(
          friends: [],
          incoming: [sampleFriendRequest(id: 'req-1')],
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await scrollUntilFound(tester, find.textContaining('1 pending request'));

      expect(find.textContaining('1 pending request'), findsOneWidget);
    });

    testWidgets('shows real unread message count', (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        messagesRepository: FakeMessagesRepository(
          conversations: [sampleConversation(unreadCount: 2)],
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await scrollUntilFound(tester, find.textContaining('2 unread'));

      expect(find.textContaining('2 unread'), findsOneWidget);
    });
  });
}
