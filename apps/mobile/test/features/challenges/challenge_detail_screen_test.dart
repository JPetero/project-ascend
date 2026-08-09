import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/challenges/presentation/screens/challenge_detail_screen.dart';
import 'package:mobile/features/sharing/presentation/screens/share_content_screen.dart';

import '../../helpers/fake_challenges_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets(
    'a participant can share their progress (Build Session 10 Parts 20-21 '
    '— challengeResult existed since Build Session 9 Part 3 but was never '
    'used)',
    (tester) async {
      final repository = FakeChallengesRepository(
        mine: [sampleChallenge(id: 'challenge-1', title: 'August step-up')],
      );
      final container = await createTestContainer(
        signedIn: true,
        challengesRepository: repository,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ChallengeDetailScreen(challengeId: 'challenge-1'),
          ),
        ),
      );
      await pumpForAsyncSettle(tester);

      await tester.tap(find.byTooltip('Share your progress'));
      await pumpForAsyncSettle(tester);

      expect(find.byType(ShareContentScreen), findsOneWidget);
    },
  );

  testWidgets('a non-participant has no share action', (tester) async {
    final repository = FakeChallengesRepository(
      discoverable: [
        sampleChallenge(id: 'challenge-1', title: 'August step-up'),
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
        child: const MaterialApp(
          home: ChallengeDetailScreen(challengeId: 'challenge-1'),
        ),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.byTooltip('Share your progress'), findsNothing);
  });
}
