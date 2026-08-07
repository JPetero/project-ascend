import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../friends/presentation/providers/friends_controller.dart';
import '../../domain/joint_workout_session.dart';
import '../providers/joint_workout_session_detail_controller.dart';

/// One joint workout session's full lifecycle — Build Session 8 Part 9.
/// Actions shown depend on the caller's own participant status and
/// whether they're the host, mirroring
/// JointWorkoutSessionsService's rules exactly rather than
/// re-implementing them client-side.
class JointWorkoutSessionDetailScreen extends ConsumerWidget {
  const JointWorkoutSessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      jointWorkoutSessionDetailControllerProvider(sessionId),
    );
    final controller = ref.read(
      jointWorkoutSessionDetailControllerProvider(sessionId).notifier,
    );
    final myUserId = ref.watch(
      authControllerProvider.select((s) => s.user?.id),
    );
    final session = state.session;

    return Scaffold(
      appBar: AppBar(title: Text(session?.title ?? 'Joint workout')),
      body: SafeArea(
        child: state.isLoading && session == null
            ? const AscendLoadingIndicator()
            : session == null
            ? AscendEmptyState(
                icon: Icons.error_outline,
                title: 'Session not found',
                message: state.error ?? 'This session is no longer available.',
              )
            : RefreshIndicator(
                onRefresh: controller.load,
                child: ListView(
                  padding: const EdgeInsets.all(AscendSpacing.md),
                  children: [
                    _StatusBanner(session: session),
                    const SizedBox(height: AscendSpacing.md),
                    Text(
                      'Participants',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AscendSpacing.sm),
                    for (final participant in session.participants)
                      _ParticipantTile(participant: participant),
                    const SizedBox(height: AscendSpacing.lg),
                    _ActionBar(
                      session: session,
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
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.session});

  final JointWorkoutSession session;

  @override
  Widget build(BuildContext context) {
    return AscendCard(
      child: Text(switch (session.status) {
        JointWorkoutSessionStatus.created =>
          'Waiting for everyone to get ready.',
        JointWorkoutSessionStatus.inProgress =>
          'Session in progress — go at your own pace.',
        JointWorkoutSessionStatus.finished => 'Session finished. Nice work!',
        JointWorkoutSessionStatus.canceled => 'This session was canceled.',
      }),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.participant});

  final JointWorkoutParticipant participant;

  @override
  Widget build(BuildContext context) {
    return AscendCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18),
              const SizedBox(width: AscendSpacing.sm),
              Expanded(child: Text(_statusLabel(participant.status))),
            ],
          ),
          for (final result in participant.results)
            Padding(
              padding: const EdgeInsets.only(
                top: AscendSpacing.xs,
                left: AscendSpacing.lg,
              ),
              child: Text(
                [
                  if (result.exerciseName != null) result.exerciseName,
                  if (result.setsCompleted != null)
                    '${result.setsCompleted} sets',
                  if (result.durationSeconds != null)
                    '${result.durationSeconds}s',
                  if (result.distanceMeters != null)
                    '${result.distanceMeters}m',
                  if (result.isPersonalRecord) 'PR!',
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  String _statusLabel(JointWorkoutParticipantStatus status) {
    switch (status) {
      case JointWorkoutParticipantStatus.invited:
        return 'Invited';
      case JointWorkoutParticipantStatus.accepted:
        return 'Accepted';
      case JointWorkoutParticipantStatus.declined:
        return 'Declined';
      case JointWorkoutParticipantStatus.ready:
        return 'Ready';
      case JointWorkoutParticipantStatus.active:
        return 'Working out';
      case JointWorkoutParticipantStatus.finished:
        return 'Finished';
      case JointWorkoutParticipantStatus.left:
        return 'Left';
    }
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({
    required this.session,
    required this.myUserId,
    required this.controller,
    required this.isActing,
  });

  final JointWorkoutSession session;
  final String? myUserId;
  final JointWorkoutSessionDetailController controller;
  final bool isActing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = session.participants
        .where((p) => p.userId == myUserId)
        .cast<JointWorkoutParticipant?>()
        .firstWhere((_) => true, orElse: () => null);
    final isHost = session.hostId == myUserId;
    final actions = <Widget>[];

    if (me?.status == JointWorkoutParticipantStatus.invited) {
      actions.add(
        FilledButton(
          onPressed: isActing ? null : controller.accept,
          child: const Text('Accept invite'),
        ),
      );
      actions.add(
        OutlinedButton(
          onPressed: isActing ? null : controller.decline,
          child: const Text('Decline'),
        ),
      );
    }
    if (me?.status == JointWorkoutParticipantStatus.accepted) {
      actions.add(
        FilledButton(
          onPressed: isActing ? null : controller.markReady,
          child: const Text("I'm ready"),
        ),
      );
    }
    if (isHost && session.status == JointWorkoutSessionStatus.created) {
      actions.add(
        FilledButton(
          onPressed: isActing ? null : controller.start,
          child: const Text('Start session'),
        ),
      );
      actions.add(
        OutlinedButton(
          onPressed: isActing ? null : () => _showInviteDialog(context, ref),
          child: const Text('Invite a friend'),
        ),
      );
    }
    if (me?.status == JointWorkoutParticipantStatus.active) {
      actions.add(
        FilledButton(
          onPressed: isActing ? null : () => _showProgressDialog(context),
          child: const Text('Log progress'),
        ),
      );
      actions.add(
        OutlinedButton(
          onPressed: isActing ? null : controller.finish,
          child: const Text('Finish'),
        ),
      );
    }
    final canLeave =
        me != null &&
        ![
          JointWorkoutParticipantStatus.finished,
          JointWorkoutParticipantStatus.declined,
          JointWorkoutParticipantStatus.left,
        ].contains(me.status);
    if (canLeave) {
      actions.add(
        TextButton(
          onPressed: isActing ? null : controller.leave,
          child: const Text('Leave session'),
        ),
      );
    }
    if (isHost &&
        session.status != JointWorkoutSessionStatus.finished &&
        session.status != JointWorkoutSessionStatus.canceled) {
      actions.add(
        TextButton(
          onPressed: isActing ? null : controller.cancel,
          child: const Text('Cancel session'),
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

  Future<void> _showProgressDialog(BuildContext context) async {
    final exerciseController = TextEditingController();
    final setsController = TextEditingController();
    var isPersonalRecord = false;

    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Log progress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AscendTextField(
                label: 'Exercise',
                controller: exerciseController,
              ),
              const SizedBox(height: AscendSpacing.sm),
              AscendTextField(
                label: 'Sets completed',
                controller: setsController,
                keyboardType: TextInputType.number,
              ),
              CheckboxListTile(
                value: isPersonalRecord,
                title: const Text('Personal record'),
                onChanged: (checked) =>
                    setState(() => isPersonalRecord = checked == true),
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (submit != true) return;
    await controller.submitProgress(
      exerciseName: exerciseController.text.trim().isEmpty
          ? null
          : exerciseController.text.trim(),
      setsCompleted: int.tryParse(setsController.text.trim()),
      isPersonalRecord: isPersonalRecord,
    );
  }

  Future<void> _showInviteDialog(BuildContext context, WidgetRef ref) async {
    final friends = ref.read(friendsControllerProvider).friends;
    final alreadyInvited = session.participants.map((p) => p.userId).toSet();
    final invitable = friends
        .where((f) => !alreadyInvited.contains(f.userId))
        .toList();

    if (invitable.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Invite a friend'),
          content: const Text('All your friends have already been invited.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    final chosen = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Invite a friend'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final friend in invitable)
                ListTile(
                  title: Text(friend.displayName),
                  onTap: () => Navigator.of(dialogContext).pop(friend.userId),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (chosen != null) {
      await controller.invite(chosen);
    }
  }
}
