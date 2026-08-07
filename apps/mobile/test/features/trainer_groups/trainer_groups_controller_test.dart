import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/trainer_groups/domain/trainer_group.dart';
import 'package:mobile/features/trainer_groups/presentation/providers/trainer_groups_controller.dart';

import '../../helpers/fake_trainer_groups_repository.dart';

void main() {
  late FakeTrainerGroupsRepository repository;

  setUp(() {
    repository = FakeTrainerGroupsRepository();
  });

  test('loads groups and invitations on construction', () async {
    repository.groups.add(sampleGroup(isOwnGroup: true));
    repository.invitations.add(
      TrainerGroupInvitation(
        id: 'invite-1',
        groupId: 'group-2',
        inviterId: 'someone',
        inviteeId: 'me',
        status: TrainerGroupInvitationStatus.pending,
        createdAt: DateTime.utc(2026, 8, 6),
      ),
    );
    final controller = TrainerGroupsController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.groups, hasLength(1));
    expect(controller.state.invitations, hasLength(1));
    expect(controller.state.isLoading, isFalse);
  });

  test('accepting an invitation removes it and refreshes groups', () async {
    repository.invitations.add(
      TrainerGroupInvitation(
        id: 'invite-1',
        groupId: 'group-2',
        inviterId: 'someone',
        inviteeId: 'me',
        status: TrainerGroupInvitationStatus.pending,
        createdAt: DateTime.utc(2026, 8, 6),
      ),
    );
    final controller = TrainerGroupsController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final ok = await controller.acceptInvitation('invite-1');

    expect(ok, isTrue);
    expect(controller.state.invitations, isEmpty);
  });

  test(
    'declining an invitation removes it from state without a full refresh',
    () async {
      repository.invitations.add(
        TrainerGroupInvitation(
          id: 'invite-1',
          groupId: 'group-2',
          inviterId: 'someone',
          inviteeId: 'me',
          status: TrainerGroupInvitationStatus.pending,
          createdAt: DateTime.utc(2026, 8, 6),
        ),
      );
      final controller = TrainerGroupsController(repository: repository);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      final ok = await controller.declineInvitation('invite-1');

      expect(ok, isTrue);
      expect(controller.state.invitations, isEmpty);
    },
  );
}
