import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/sports/domain/sport_match.dart';
import 'package:mobile/features/sports/presentation/providers/sport_match_detail_controller.dart';

import '../../helpers/fake_sports_repository.dart';

void main() {
  test('loads the match on construction', () async {
    final repository = FakeSportsRepository(
      matches: [sampleSportMatch(id: 'match-1')],
    );
    final controller = SportMatchDetailController(
      repository: repository,
      matchId: 'match-1',
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.match?.id, 'match-1');
    expect(controller.state.isLoading, isFalse);
  });

  test('accept moves the caller from invited to accepted', () async {
    final repository = FakeSportsRepository(
      matches: [
        sampleSportMatch(
          id: 'match-1',
          createdById: 'host-1',
          participants: [
            sampleSportParticipant(
              userId: 'user-1',
              status: SportMatchParticipantStatus.invited,
            ),
          ],
        ),
      ],
    );
    final controller = SportMatchDetailController(
      repository: repository,
      matchId: 'match-1',
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final ok = await controller.accept();

    expect(ok, isTrue);
    expect(
      controller.state.match!.participants.single.status,
      SportMatchParticipantStatus.accepted,
    );
  });

  test(
    'markReady on both participants moves the match to READY, then start moves it to IN_PROGRESS',
    () async {
      final repository = FakeSportsRepository(
        matches: [
          sampleSportMatch(
            id: 'match-1',
            participants: [
              sampleSportParticipant(userId: 'user-1'),
              sampleSportParticipant(
                id: 'p2',
                userId: 'friend-1',
                status: SportMatchParticipantStatus.ready,
              ),
            ],
          ),
        ],
      );
      final controller = SportMatchDetailController(
        repository: repository,
        matchId: 'match-1',
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      await controller.markReady();
      expect(controller.state.match!.status, SportMatchStatus.ready);

      await controller.start();
      expect(controller.state.match!.status, SportMatchStatus.inProgress);
    },
  );

  test('proposeScore moves the match to SCORE_PENDING', () async {
    final repository = FakeSportsRepository(
      matches: [
        sampleSportMatch(id: 'match-1', status: SportMatchStatus.inProgress),
      ],
    );
    final controller = SportMatchDetailController(
      repository: repository,
      matchId: 'match-1',
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.proposeScore(21, 15);

    expect(controller.state.match!.status, SportMatchStatus.scorePending);
    expect(controller.state.match!.scoreProposals.single.proposerScore, 21);
  });

  test('confirmScore moves the match to CONFIRMED', () async {
    final repository = FakeSportsRepository(
      matches: [
        sampleSportMatch(id: 'match-1', status: SportMatchStatus.scorePending),
      ],
    );
    final controller = SportMatchDetailController(
      repository: repository,
      matchId: 'match-1',
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.confirmScore();

    expect(controller.state.match!.status, SportMatchStatus.confirmed);
  });

  test(
    'disputeScore records the reason and moves the match to DISPUTED',
    () async {
      final repository = FakeSportsRepository(
        matches: [
          sampleSportMatch(
            id: 'match-1',
            status: SportMatchStatus.scorePending,
          ),
        ],
      );
      final controller = SportMatchDetailController(
        repository: repository,
        matchId: 'match-1',
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      await controller.disputeScore('That score is wrong.');

      expect(repository.lastDisputeReason, 'That score is wrong.');
      expect(controller.state.match!.status, SportMatchStatus.disputed);
    },
  );

  test('voidMatch moves the match to VOID', () async {
    final repository = FakeSportsRepository(
      matches: [
        sampleSportMatch(id: 'match-1', status: SportMatchStatus.disputed),
      ],
    );
    final controller = SportMatchDetailController(
      repository: repository,
      matchId: 'match-1',
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.voidMatch();

    expect(controller.state.match!.status, SportMatchStatus.void_);
  });
}
