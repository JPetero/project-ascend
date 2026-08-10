import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/trainer_groups/presentation/providers/my_assignments_controller.dart';

import '../../helpers/fake_trainer_groups_repository.dart';

void main() {
  test('loads the caller\'s own assignments on construction', () async {
    final repository = FakeTrainerGroupsRepository();
    await repository.createAssignments(
      'group-1',
      workoutPlanId: 'plan-1',
      assigneeUserIds: ['me'],
    );
    final controller = MyAssignmentsController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.assignments, hasLength(1));
  });

  test(
    'accept() clones the plan and returns its id, refreshing state',
    () async {
      final repository = FakeTrainerGroupsRepository();
      await repository.createAssignments(
        'group-1',
        workoutPlanId: 'plan-1',
        assigneeUserIds: ['me'],
      );
      final controller = MyAssignmentsController(repository: repository);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);
      final assignmentId = controller.state.assignments.single.id;

      final workoutPlanId = await controller.accept(assignmentId);

      expect(workoutPlanId, 'cloned-plan-1');
      expect(
        controller.state.assignments.single.assignedPlanId,
        'cloned-plan-1',
      );
    },
  );

  test('dismiss() removes the assignment and is reflected in state', () async {
    final repository = FakeTrainerGroupsRepository();
    await repository.createAssignments(
      'group-1',
      workoutPlanId: 'plan-1',
      assigneeUserIds: ['me'],
    );
    final controller = MyAssignmentsController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);
    final assignmentId = controller.state.assignments.single.id;

    final ok = await controller.dismiss(assignmentId);

    expect(ok, isTrue);
    expect(controller.state.assignments, isEmpty);
  });

  test(
    'decline() replaces the assignment in place with status declined (Build Session 13 Part 4)',
    () async {
      final repository = FakeTrainerGroupsRepository();
      await repository.createAssignments(
        'group-1',
        workoutPlanId: 'plan-1',
        assigneeUserIds: ['me'],
      );
      final controller = MyAssignmentsController(repository: repository);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);
      final assignmentId = controller.state.assignments.single.id;

      final ok = await controller.decline(assignmentId);

      expect(ok, isTrue);
      expect(controller.state.assignments, hasLength(1));
      expect(controller.state.assignments.single.status.name, 'declined');
    },
  );
}
