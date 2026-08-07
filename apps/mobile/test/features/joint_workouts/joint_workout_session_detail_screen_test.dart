import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/joint_workouts/domain/joint_workout_session.dart';
import 'package:mobile/features/joint_workouts/presentation/screens/joint_workout_session_detail_screen.dart';

import '../../helpers/fake_joint_workout_sessions_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets(
    'an invited participant can accept, moving past the invite banner',
    (tester) async {
      final repository = FakeJointWorkoutSessionsRepository(
        sessions: [
          sampleJointWorkoutSession(
            id: 'session-1',
            hostId: 'host-1',
            participants: [
              sampleParticipant(
                userId: 'user-1',
                status: JointWorkoutParticipantStatus.invited,
              ),
            ],
          ),
        ],
      );
      final container = await createTestContainer(
        signedIn: true,
        jointWorkoutSessionsRepository: repository,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: JointWorkoutSessionDetailScreen(sessionId: 'session-1'),
          ),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.text('Accept invite'), findsOneWidget);

      await tester.tap(find.text('Accept invite'));
      await pumpForAsyncSettle(tester);

      expect(find.text('Accept invite'), findsNothing);
      expect(find.text("I'm ready"), findsOneWidget);
    },
  );

  testWidgets('the host marks ready and starts the session', (tester) async {
    final repository = FakeJointWorkoutSessionsRepository(
      sessions: [
        sampleJointWorkoutSession(
          id: 'session-1',
          hostId: 'user-1',
          participants: [
            sampleParticipant(
              userId: 'user-1',
              status: JointWorkoutParticipantStatus.accepted,
            ),
          ],
        ),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      jointWorkoutSessionsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: JointWorkoutSessionDetailScreen(sessionId: 'session-1'),
        ),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text("I'm ready"));
    await pumpForAsyncSettle(tester);
    await tester.tap(find.text('Start session'));
    await pumpForAsyncSettle(tester);

    expect(
      find.text('Session in progress — go at your own pace.'),
      findsOneWidget,
    );
    expect(find.text('Log progress'), findsOneWidget);
  });

  testWidgets('an active participant can log progress and see it appear', (
    tester,
  ) async {
    final repository = FakeJointWorkoutSessionsRepository(
      sessions: [
        sampleJointWorkoutSession(
          id: 'session-1',
          status: JointWorkoutSessionStatus.inProgress,
          participants: [
            sampleParticipant(
              userId: 'user-1',
              status: JointWorkoutParticipantStatus.active,
            ),
          ],
        ),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      jointWorkoutSessionsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: JointWorkoutSessionDetailScreen(sessionId: 'session-1'),
        ),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Log progress'));
    await pumpForAsyncSettle(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Squat');
    await tester.tap(find.text('Save'));
    await pumpForAsyncSettle(tester);

    expect(find.textContaining('Squat'), findsOneWidget);
  });
}
