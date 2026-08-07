import 'package:flutter_test/flutter_test.dart';
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
}
