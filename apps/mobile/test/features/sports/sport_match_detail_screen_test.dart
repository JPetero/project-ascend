import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/sports/domain/sport_match.dart';
import 'package:mobile/features/sports/presentation/screens/sport_match_detail_screen.dart';

import '../../helpers/fake_sports_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('an invited participant can accept the challenge', (
    tester,
  ) async {
    final repository = FakeSportsRepository(
      matches: [
        sampleSportMatch(
          id: 'match-1',
          createdById: 'host-1',
          participants: [
            sampleSportParticipant(
              userId: 'user-1',
              status: SportMatchParticipantStatus.invited,
            ),
          ],
        ),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      sportsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SportMatchDetailScreen(matchId: 'match-1'),
        ),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Accept challenge'), findsOneWidget);

    await tester.tap(find.text('Accept challenge'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Accept challenge'), findsNothing);
    expect(find.text("I'm ready"), findsOneWidget);
  });

  testWidgets('proposing and confirming a score moves the match to CONFIRMED', (
    tester,
  ) async {
    final repository = FakeSportsRepository(
      matches: [
        sampleSportMatch(id: 'match-1', status: SportMatchStatus.inProgress),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      sportsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SportMatchDetailScreen(matchId: 'match-1'),
        ),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Propose final score'));
    await pumpForAsyncSettle(tester);
    await tester.enterText(find.byType(TextFormField).at(0), '21');
    await tester.enterText(find.byType(TextFormField).at(1), '15');
    await tester.tap(find.text('Propose'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Confirm score'), findsOneWidget);

    await tester.tap(find.text('Confirm score'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Confirmed — ratings have been updated.'), findsOneWidget);
  });
}
