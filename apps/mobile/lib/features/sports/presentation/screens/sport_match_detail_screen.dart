import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../sharing/domain/share_content.dart';
import '../../../sharing/presentation/screens/share_content_screen.dart';
import '../../domain/sport_match.dart';
import '../providers/sport_match_detail_controller.dart';

/// One sports match's full lifecycle — Build Session 8 Part 10. Actions
/// shown depend on the match's status and the caller's own participant
/// status, mirroring SportsService's rules exactly.
class SportMatchDetailScreen extends ConsumerWidget {
  const SportMatchDetailScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sportMatchDetailControllerProvider(matchId));
    final controller = ref.read(
      sportMatchDetailControllerProvider(matchId).notifier,
    );
    final myUserId = ref.watch(
      authControllerProvider.select((s) => s.user?.id),
    );
    final match = state.match;

    final sportName = match?.sportName ?? 'Sports';

    return Scaffold(
      appBar: AppBar(
        title: Text('$sportName match'),
        actions: [
          if (match != null &&
              match.status == SportMatchStatus.confirmed &&
              match.scoreProposals.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.ios_share_outlined),
              tooltip: 'Share match result',
              onPressed: () {
                final score = match.scoreProposals.first;
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => ShareContentScreen(
                      content: ShareContent(
                        type: ShareContentType.sportsMatchResult,
                        title: 'Match confirmed!',
                        subtitle: sportName,
                        statLines: [
                          ShareStatLine(
                            label: 'Final score',
                            value:
                                '${score.proposerScore} - ${score.opponentScore}',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: state.isLoading && match == null
            ? const AscendLoadingIndicator()
            : match == null
            ? AscendEmptyState(
                icon: Icons.error_outline,
                title: 'Match not found',
                message: state.error ?? 'This match is no longer available.',
              )
            : RefreshIndicator(
                onRefresh: controller.load,
                child: ListView(
                  padding: const EdgeInsets.all(AscendSpacing.md),
                  children: [
                    if (match.flagged)
                      const AscendCard(
                        child: Text(
                          'This match was flagged for an unusually high match '
                          'frequency between these two players and is under '
                          'review. It still counts unless corrected.',
                        ),
                      ),
                    AscendCard(child: Text(_statusMessage(match.status))),
                    const SizedBox(height: AscendSpacing.md),
                    if (match.scoreProposals.isNotEmpty)
                      AscendCard(
                        child: Text(
                          'Latest proposed score: '
                          '${match.scoreProposals.first.proposerScore} - '
                          '${match.scoreProposals.first.opponentScore}',
                        ),
                      ),
                    const SizedBox(height: AscendSpacing.lg),
                    _ActionBar(
                      match: match,
                      myUserId: myUserId,
                      controller: controller,
                      isActing: state.isActing,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _statusMessage(SportMatchStatus status) {
    switch (status) {
      case SportMatchStatus.created:
      case SportMatchStatus.invited:
        return 'Waiting for a response to the challenge.';
      case SportMatchStatus.ready:
        return 'Both players are ready to start.';
      case SportMatchStatus.inProgress:
        return 'Match in progress — propose the final score when you finish.';
      case SportMatchStatus.scorePending:
        return 'A score was proposed and is awaiting confirmation.';
      case SportMatchStatus.disputed:
        return 'The proposed score was disputed.';
      case SportMatchStatus.confirmed:
        return 'Confirmed — ratings have been updated.';
      case SportMatchStatus.canceled:
        return 'This match was canceled.';
      case SportMatchStatus.void_:
        return 'This match was voided and does not affect ratings.';
    }
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.match,
    required this.myUserId,
    required this.controller,
    required this.isActing,
  });

  final SportMatch match;
  final String? myUserId;
  final SportMatchDetailController controller;
  final bool isActing;

  @override
  Widget build(BuildContext context) {
    final me = match.participants
        .where((p) => p.userId == myUserId)
        .cast<SportMatchParticipant?>()
        .firstWhere((_) => true, orElse: () => null);
    final actions = <Widget>[];

    if (me?.status == SportMatchParticipantStatus.invited) {
      actions.add(
        FilledButton(
          onPressed: isActing ? null : controller.accept,
          child: const Text('Accept challenge'),
        ),
      );
      actions.add(
        OutlinedButton(
          onPressed: isActing ? null : controller.decline,
          child: const Text('Decline'),
        ),
      );
    }
    if (me?.status == SportMatchParticipantStatus.accepted) {
      actions.add(
        FilledButton(
          onPressed: isActing ? null : controller.markReady,
          child: const Text("I'm ready"),
        ),
      );
    }
    if (match.status == SportMatchStatus.ready) {
      actions.add(
        FilledButton(
          onPressed: isActing ? null : controller.start,
          child: const Text('Start match'),
        ),
      );
    }
    if (match.status == SportMatchStatus.inProgress ||
        match.status == SportMatchStatus.disputed) {
      actions.add(
        FilledButton(
          onPressed: isActing ? null : () => _showProposeDialog(context),
          child: const Text('Propose final score'),
        ),
      );
    }
    if (match.status == SportMatchStatus.scorePending) {
      actions.add(
        FilledButton(
          onPressed: isActing ? null : controller.confirmScore,
          child: const Text('Confirm score'),
        ),
      );
      actions.add(
        OutlinedButton(
          onPressed: isActing ? null : () => _showDisputeDialog(context),
          child: const Text('Dispute'),
        ),
      );
    }
    if (match.status == SportMatchStatus.disputed) {
      actions.add(
        TextButton(
          onPressed: isActing ? null : controller.voidMatch,
          child: const Text('Void match'),
        ),
      );
    }
    if (match.status == SportMatchStatus.created ||
        match.status == SportMatchStatus.invited ||
        match.status == SportMatchStatus.ready) {
      actions.add(
        TextButton(
          onPressed: isActing ? null : controller.cancel,
          child: const Text('Cancel match'),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AscendSpacing.sm,
      runSpacing: AscendSpacing.sm,
      children: actions,
    );
  }

  Future<void> _showProposeDialog(BuildContext context) async {
    final proposerController = TextEditingController();
    final opponentController = TextEditingController();

    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Propose final score'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AscendTextField(
              label: 'Your score',
              controller: proposerController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AscendSpacing.sm),
            AscendTextField(
              label: "Opponent's score",
              controller: opponentController,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Propose'),
          ),
        ],
      ),
    );

    if (submit != true) return;
    final proposerScore = int.tryParse(proposerController.text.trim());
    final opponentScore = int.tryParse(opponentController.text.trim());
    if (proposerScore == null || opponentScore == null) return;
    await controller.proposeScore(proposerScore, opponentScore);
  }

  Future<void> _showDisputeDialog(BuildContext context) async {
    final reasonController = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dispute this score'),
        content: AscendTextField(
          label: 'Reason',
          controller: reasonController,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Dispute'),
          ),
        ],
      ),
    );
    if (submit == true && reasonController.text.trim().isNotEmpty) {
      await controller.disputeScore(reasonController.text.trim());
    }
  }
}
