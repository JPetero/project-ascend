import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/joint_workouts/presentation/providers/joint_workout_sessions_controller.dart';

import '../../helpers/fake_joint_workout_sessions_repository.dart';

void main() {
  test('loads the caller\'s sessions on construction', () async {
    final repository = FakeJointWorkoutSessionsRepository(
      sessions: [sampleJointWorkoutSession(id: 'session-1')],
    );
    final controller = JointWorkoutSessionsController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.sessions, hasLength(1));
    expect(controller.state.isLoading, isFalse);
  });

  test('create adds a new session and refreshes the list', () async {
    final repository = FakeJointWorkoutSessionsRepository();
    final controller = JointWorkoutSessionsController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final session = await controller.create(
      title: 'Push day',
      inviteeIds: ['friend-1'],
    );

    expect(session, isNotNull);
    expect(controller.state.sessions, hasLength(1));
    expect(controller.state.sessions.single.title, 'Push day');
  });
}
