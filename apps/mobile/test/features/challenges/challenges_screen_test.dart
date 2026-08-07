import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/challenges/presentation/screens/challenges_screen.dart';

import '../../helpers/fake_challenges_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows an honest empty state with no challenges', (tester) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ChallengesScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('No challenges yet'), findsOneWidget);
  });

  testWidgets('lists a joined challenge with its participant count', (
    tester,
  ) async {
    final repository = FakeChallengesRepository(
      mine: [
        sampleChallenge(
          id: 'challenge-1',
          title: 'August step-up',
          creatorId: 'me',
          participantCount: 3,
        ),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      challengesRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ChallengesScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('August step-up'), findsOneWidget);
    expect(find.textContaining('3 joined'), findsOneWidget);
  });
}
