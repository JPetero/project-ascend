import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/promote/presentation/providers/promote_controller.dart';

import '../../helpers/fake_promote_repository.dart';

void main() {
  test('loads the caller\'s campaigns on construction', () async {
    final repository = FakePromoteRepository(campaigns: [sampleCampaign()]);
    final controller = PromoteController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.campaigns, hasLength(1));
    expect(controller.state.isLoading, isFalse);
  });

  test('starts empty with no campaigns', () async {
    final repository = FakePromoteRepository();
    final controller = PromoteController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.campaigns, isEmpty);
  });

  test('refresh reloads campaigns from the repository', () async {
    final repository = FakePromoteRepository();
    final controller = PromoteController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    repository.campaigns.add(sampleCampaign());
    await controller.refresh();

    expect(controller.state.campaigns, hasLength(1));
  });
}
