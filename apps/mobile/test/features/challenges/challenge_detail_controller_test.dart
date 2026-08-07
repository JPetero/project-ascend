import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/challenges/domain/challenge.dart';
import 'package:mobile/features/challenges/presentation/providers/challenge_detail_controller.dart';

import '../../helpers/fake_challenges_repository.dart';

void main() {
  test('loads a challenge and reflects participant progress', () async {
    final repository = FakeChallengesRepository(
      mine: [sampleChallenge(id: 'challenge-1', creatorId: 'me')],
    );
    repository.detailsById['challenge-1'] = ChallengeDetail(
      challenge: sampleChallenge(id: 'challenge-1', creatorId: 'me'),
      isParticipant: true,
      participants: const [
        ChallengeParticipantProgress(userId: 'me', activeDays: 3, totalDays: 5),
      ],
    );
    final controller = ChallengeDetailController(
      repository: repository,
      challengeId: 'challenge-1',
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.detail?.isParticipant, isTrue);
    expect(controller.state.detail?.participants, hasLength(1));
  });

  test('leaving removes the challenge from the caller\'s list', () async {
    final repository = FakeChallengesRepository(
      mine: [sampleChallenge(id: 'challenge-1', creatorId: 'me')],
    );
    final controller = ChallengeDetailController(
      repository: repository,
      challengeId: 'challenge-1',
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final ok = await controller.leave();

    expect(ok, isTrue);
    expect(repository.mine, isEmpty);
  });
}
