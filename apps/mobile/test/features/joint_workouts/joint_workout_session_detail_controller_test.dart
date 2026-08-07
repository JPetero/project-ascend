import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/joint_workouts/domain/joint_workout_session.dart';
import 'package:mobile/features/joint_workouts/presentation/providers/joint_workout_session_detail_controller.dart';

import '../../helpers/fake_joint_workout_sessions_repository.dart';

void main() {
  test('loads the session on construction', () async {
    final repository = FakeJointWorkoutSessionsRepository(
      sessions: [sampleJointWorkoutSession(id: 'session-1')],
    );
    final controller = JointWorkoutSessionDetailController(
      repository: repository,
      sessionId: 'session-1',
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.session?.id, 'session-1');
    expect(controller.state.isLoading, isFalse);
  });

  test('accept moves the caller from invited to accepted', () async {
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
    final controller = JointWorkoutSessionDetailController(
      repository: repository,
      sessionId: 'session-1',
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final ok = await controller.accept();

    expect(ok, isTrue);
    expect(
      controller.state.session!.participants.single.status,
      JointWorkoutParticipantStatus.accepted,
    );
  });

  test(
    'markReady then start transitions an accepted participant to active',
    () async {
      final repository = FakeJointWorkoutSessionsRepository(
        sessions: [
          sampleJointWorkoutSession(
            id: 'session-1',
            participants: [
              sampleParticipant(
                userId: 'user-1',
                status: JointWorkoutParticipantStatus.accepted,
              ),
            ],
          ),
        ],
      );
      final controller = JointWorkoutSessionDetailController(
        repository: repository,
        sessionId: 'session-1',
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      await controller.markReady();
      await controller.start();

      expect(
        controller.state.session!.status,
        JointWorkoutSessionStatus.inProgress,
      );
      expect(
        controller.state.session!.participants.single.status,
        JointWorkoutParticipantStatus.active,
      );
    },
  );

  test('submitProgress records a shared result for the caller', () async {
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
    final controller = JointWorkoutSessionDetailController(
      repository: repository,
      sessionId: 'session-1',
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.submitProgress(exerciseName: 'Squat', setsCompleted: 3);

    expect(repository.lastProgressExerciseName, 'Squat');
    expect(controller.state.session!.participants.single.results, hasLength(1));
  });

  test('leave marks the caller as left', () async {
    final repository = FakeJointWorkoutSessionsRepository(
      sessions: [
        sampleJointWorkoutSession(
          id: 'session-1',
          hostId: 'host-1',
          participants: [
            sampleParticipant(
              userId: 'user-1',
              status: JointWorkoutParticipantStatus.accepted,
            ),
          ],
        ),
      ],
    );
    final controller = JointWorkoutSessionDetailController(
      repository: repository,
      sessionId: 'session-1',
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.leave();

    expect(
      controller.state.session!.participants.single.status,
      JointWorkoutParticipantStatus.left,
    );
  });

  test('cancel marks the session canceled', () async {
    final repository = FakeJointWorkoutSessionsRepository(
      sessions: [sampleJointWorkoutSession(id: 'session-1')],
    );
    final controller = JointWorkoutSessionDetailController(
      repository: repository,
      sessionId: 'session-1',
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.cancel();

    expect(
      controller.state.session!.status,
      JointWorkoutSessionStatus.canceled,
    );
  });

  test('invite adds a new invited participant', () async {
    final repository = FakeJointWorkoutSessionsRepository(
      sessions: [sampleJointWorkoutSession(id: 'session-1')],
    );
    final controller = JointWorkoutSessionDetailController(
      repository: repository,
      sessionId: 'session-1',
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.invite('friend-2');

    expect(repository.lastInvitedUserId, 'friend-2');
    expect(
      controller.state.session!.participants
          .map((p) => p.userId)
          .contains('friend-2'),
      isTrue,
    );
  });
}
