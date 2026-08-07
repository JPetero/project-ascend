import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/challenges/presentation/providers/challenges_controller.dart';

import '../../helpers/fake_challenges_repository.dart';

void main() {
  test('loads mine and discoverable challenges on construction', () async {
    final repository = FakeChallengesRepository(
      mine: [sampleChallenge(id: 'challenge-1', creatorId: 'me')],
      discoverable: [
        sampleChallenge(id: 'challenge-2', creatorId: 'someone-else'),
      ],
    );
    final controller = ChallengesController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.mine, hasLength(1));
    expect(controller.state.discoverable, hasLength(1));
    expect(controller.state.isLoading, isFalse);
  });

  test('joining moves a challenge from discoverable into mine', () async {
    final repository = FakeChallengesRepository(
      discoverable: [
        sampleChallenge(id: 'challenge-2', creatorId: 'someone-else'),
      ],
    );
    final controller = ChallengesController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final ok = await controller.join('challenge-2');

    expect(ok, isTrue);
    expect(controller.state.mine.map((c) => c.id), contains('challenge-2'));
    expect(controller.state.discoverable, isEmpty);
  });
}
