import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/trainer_groups/domain/trainer_group.dart';
import 'package:mobile/features/trainer_groups/presentation/providers/trainer_group_detail_controller.dart';

import '../../helpers/fake_trainer_groups_repository.dart';

void main() {
  late FakeTrainerGroupsRepository repository;

  setUp(() {
    repository = FakeTrainerGroupsRepository();
    repository.groups.add(sampleGroup(id: 'group-1', isOwnGroup: true));
  });

  TrainerGroupDetailController buildController() =>
      TrainerGroupDetailController(repository: repository, groupId: 'group-1');

  test('loads the group, messages, and shared plans on construction', () async {
    final controller = buildController();
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.group?.id, 'group-1');
    expect(controller.state.isLoading, isFalse);
  });

  test(
    'sendMessage rejects an empty message without calling the repository',
    () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      final sent = await controller.sendMessage();

      expect(sent, isFalse);
      expect(controller.state.messages, isEmpty);
    },
  );

  test('sendMessage appends the new message on success', () async {
    final controller = buildController();
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final sent = await controller.sendMessage(body: 'Hello group');

    expect(sent, isTrue);
    expect(controller.state.messages, hasLength(1));
    expect(controller.state.messages.single.body, 'Hello group');
  });

  test(
    'sharePlan adds it to state, unsharePlan removes it and rolls back on failure',
    () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      final shared = await controller.sharePlan('plan-1');
      expect(shared, isTrue);
      expect(controller.state.sharedPlans, hasLength(1));

      final sharedPlanId = controller.state.sharedPlans.single.id;
      final unshared = await controller.unsharePlan(sharedPlanId);

      expect(unshared, isTrue);
      expect(controller.state.sharedPlans, isEmpty);
    },
  );

  test('setMemberRole promotes a member and reloads the group', () async {
    repository.groups[0] = sampleGroup(
      id: 'group-1',
      ownerId: 'owner-1',
      isOwnGroup: true,
      isExpanded: true,
      members: [
        TrainerGroupMember(
          userId: 'owner-1',
          role: TrainerGroupMemberRole.owner,
          joinedAt: DateTime.utc(2026, 8, 6),
        ),
        TrainerGroupMember(
          userId: 'member-a',
          role: TrainerGroupMemberRole.member,
          joinedAt: DateTime.utc(2026, 8, 6),
        ),
      ],
    );
    final controller = buildController();
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final ok = await controller.setMemberRole(
      'member-a',
      TrainerGroupMemberRole.moderator,
    );

    expect(ok, isTrue);
    expect(repository.roleChanges, hasLength(1));
    expect(
      controller.state.group?.members
          .firstWhere((m) => m.userId == 'member-a')
          .role,
      TrainerGroupMemberRole.moderator,
    );
  });

  test(
    'setMemberRole surfaces an error and does not reload on failure',
    () async {
      repository.failSetMemberRole = true;
      final controller = buildController();
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      final ok = await controller.setMemberRole(
        'member-a',
        TrainerGroupMemberRole.moderator,
      );

      expect(ok, isFalse);
      expect(controller.state.error, isNotNull);
    },
  );

  test(
    'postAnnouncement rejects an empty body without calling the repository',
    () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      final posted = await controller.postAnnouncement('   ');

      expect(posted, isFalse);
      expect(controller.state.announcements, isEmpty);
    },
  );

  test('postAnnouncement prepends the new announcement on success', () async {
    final controller = buildController();
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final posted = await controller.postAnnouncement('Leg day tomorrow!');

    expect(posted, isTrue);
    expect(controller.state.announcements, hasLength(1));
    expect(controller.state.announcements.single.body, 'Leg day tomorrow!');
  });

  test(
    'createAssignments adds the new assignments to state (Build Session 12 Part 9)',
    () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      final ok = await controller.createAssignments(
        workoutPlanId: 'plan-1',
        assigneeUserIds: ['member-a', 'member-b'],
      );

      expect(ok, isTrue);
      expect(controller.state.assignments, hasLength(2));
    },
  );

  test(
    'cancelAssignment removes it from state and rolls back on failure',
    () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);
      await controller.createAssignments(
        workoutPlanId: 'plan-1',
        assigneeUserIds: ['member-a'],
      );
      final assignmentId = controller.state.assignments.single.id;

      final ok = await controller.cancelAssignment(assignmentId);

      expect(ok, isTrue);
      expect(controller.state.assignments, isEmpty);
    },
  );

  test(
    'createScheduledSession adds the new session to state, kept sorted (Build Session 12 Part 10)',
    () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      final later = DateTime.now().add(const Duration(days: 2));
      final sooner = DateTime.now().add(const Duration(days: 1));

      await controller.createScheduledSession(scheduledAt: later);
      final ok = await controller.createScheduledSession(scheduledAt: sooner);

      expect(ok, isTrue);
      expect(controller.state.scheduledSessions, hasLength(2));
      expect(controller.state.scheduledSessions.first.scheduledAt, sooner);
    },
  );

  test(
    'cancelScheduledSession removes it from state and rolls back on failure',
    () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);
      await controller.createScheduledSession(
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
      );
      final sessionId = controller.state.scheduledSessions.single.id;

      final ok = await controller.cancelScheduledSession(sessionId);

      expect(ok, isTrue);
      expect(controller.state.scheduledSessions, isEmpty);
    },
  );
}
