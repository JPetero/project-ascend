import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/design_system/design_system.dart';
import 'package:mobile/features/rankings/domain/ranking.dart';
import 'package:mobile/features/rankings/presentation/screens/rankings_screen.dart';
import 'package:mobile/features/sharing/presentation/screens/share_content_screen.dart';

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

  testWidgets(
    'the viewer can share their own rank (Build Session 10 Parts 20-21 — '
    'rankingMilestone existed since Build Session 9 Part 3 but was never used)',
    (tester) async {
      final repository = FakeRankingsRepository(
        status: const RankingMyStatus(
          optedIn: true,
          scope: RankingScope.global,
        ),
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

      await tester.tap(find.byTooltip('Share your rank'));
      await pumpForAsyncSettle(tester);

      expect(find.byType(ShareContentScreen), findsOneWidget);
    },
  );

  testWidgets(
    'the opt-in button stays disabled until every locality field for the '
    'chosen tier is filled in',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        rankingsRepository: FakeRankingsRepository(),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RankingsScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'City'));
      await pumpForAsyncSettle(tester);

      Future<void> scrollTo(Finder finder) async {
        await tester.scrollUntilVisible(
          finder,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await pumpForAsyncSettle(tester);
      }

      final optInButtonFinder = find.widgetWithText(
        AscendPrimaryButton,
        'Opt in to Rankings',
      );
      AscendPrimaryButton optInButton() =>
          tester.widget<AscendPrimaryButton>(optInButtonFinder);

      await scrollTo(optInButtonFinder);
      expect(optInButton().onPressed, isNull);

      await scrollTo(find.widgetWithText(AscendTextField, 'Country'));
      await tester.enterText(
        find.widgetWithText(AscendTextField, 'Country'),
        'Philippines',
      );
      await scrollTo(find.widgetWithText(AscendTextField, 'Region or state'));
      await tester.enterText(
        find.widgetWithText(AscendTextField, 'Region or state'),
        'Metro Manila',
      );
      await pumpForAsyncSettle(tester);
      await scrollTo(optInButtonFinder);
      expect(optInButton().onPressed, isNull);

      await scrollTo(find.widgetWithText(AscendTextField, 'City'));
      await tester.enterText(
        find.widgetWithText(AscendTextField, 'City'),
        'Quezon City',
      );
      await pumpForAsyncSettle(tester);
      await scrollTo(optInButtonFinder);

      expect(optInButton().onPressed, isNotNull);
    },
  );

  testWidgets(
    'a NATIONAL opt-in cannot select the narrower CITY leaderboard chip',
    (tester) async {
      final repository = FakeRankingsRepository(
        status: const RankingMyStatus(
          optedIn: true,
          scope: RankingScope.national,
          localityCountry: 'Philippines',
        ),
        leaderboards: {
          RankingScope.national: [
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

      final cityChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'City'),
      );
      expect(cityChip.onSelected, isNull);

      final nationalChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'National'),
      );
      expect(nationalChip.onSelected, isNotNull);
    },
  );
}
