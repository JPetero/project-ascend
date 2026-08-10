import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/trainer_group.dart';
import '../providers/scheduled_session_detail_controller.dart';

/// One trainer-group scheduled session's full detail (Build Session 13
/// continuation Part B) — RSVP going/maybe/decline/change/cancel, host
/// cancel/start, and "Join session" for eligible Going participants once
/// the host has started it. Reached either by tapping a session card in
/// TrainerGroupDetailScreen's Sessions tab, or by a
/// GROUP_SESSION_SCHEDULED / GROUP_SESSION_CANCELED push notification's
/// deep link.
class ScheduledSessionDetailScreen extends ConsumerWidget {
  const ScheduledSessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      scheduledSessionDetailControllerProvider(sessionId),
    );
    final controller = ref.read(
      scheduledSessionDetailControllerProvider(sessionId).notifier,
    );
    final viewerId = ref.watch(
      authControllerProvider.select((s) => s.user?.id),
    );
    final session = state.session;
    final group = state.group;

    return Scaffold(
      appBar: AppBar(title: Text(session?.title ?? 'Group session')),
      body: SafeArea(
        child: state.isLoading && session == null
            ? const AscendLoadingIndicator()
            : session == null || group == null
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
                    _DetailCard(session: session, group: group),
                    const SizedBox(height: AscendSpacing.md),
                    Text(
                      'Going ${session.goingCount} · '
                      'Maybe ${session.maybeCount} · '
                      "Can't go ${session.declinedCount}",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AscendSpacing.lg),
                    _ActionSection(
                      session: session,
                      group: group,
                      viewerId: viewerId,
                      controller: controller,
                      isActing: state.isActing,
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: AscendSpacing.md),
                      Text(
                        state.error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.session});

  final TrainerGroupScheduledSession session;

  @override
  Widget build(BuildContext context) {
    return AscendCard(
      child: Text(switch (session.status) {
        ScheduledSessionStatus.upcoming =>
          session.jointWorkoutSessionId != null
              ? 'This session is live.'
              : 'Upcoming session.',
        ScheduledSessionStatus.completed => 'This session has ended.',
        ScheduledSessionStatus.canceled => 'This session was canceled.',
      }),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.session, required this.group});

  final TrainerGroupScheduledSession session;
  final TrainerGroup group;

  @override
  Widget build(BuildContext context) {
    final hostName = group.members
        .where((m) => m.userId == session.createdById)
        .map((m) => m.displayName ?? 'A group member')
        .cast<String?>()
        .firstWhere((_) => true, orElse: () => null);
    final localTime = session.scheduledAt.toLocal();
    final textTheme = Theme.of(context).textTheme;

    return AscendCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (session.description != null) ...[
            Text(session.description!, style: textTheme.bodyMedium),
            const SizedBox(height: AscendSpacing.sm),
          ],
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Hosted by ${hostName ?? 'a group member'}',
          ),
          _InfoRow(
            icon: Icons.event_outlined,
            label:
                '${localTime.toString().split('.').first} '
                '(${localTime.timeZoneName})',
          ),
          if (session.durationMinutes != null)
            _InfoRow(
              icon: Icons.timer_outlined,
              label: '${session.durationMinutes} minutes',
            ),
          if (session.workoutPlanName != null)
            _InfoRow(
              icon: Icons.fitness_center_outlined,
              label: 'Plan: ${session.workoutPlanName}',
            ),
          if (session.location != null)
            _InfoRow(icon: Icons.place_outlined, label: session.location!),
          if (session.videoLink != null)
            _InfoRow(icon: Icons.videocam_outlined, label: session.videoLink!),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AscendSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: AscendSpacing.sm),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.session,
    required this.group,
    required this.viewerId,
    required this.controller,
    required this.isActing,
  });

  final TrainerGroupScheduledSession session;
  final TrainerGroup group;
  final String? viewerId;
  final ScheduledSessionDetailController controller;
  final bool isActing;

  @override
  Widget build(BuildContext context) {
    final isOwner = group.ownerId == viewerId;
    final viewerRole = group.members
        .where((m) => m.userId == viewerId)
        .map((m) => m.role)
        .cast<TrainerGroupMemberRole?>()
        .firstWhere((_) => true, orElse: () => null);
    final canManage =
        isOwner ||
        viewerRole == TrainerGroupMemberRole.moderator ||
        session.createdById == viewerId;
    final isCanceled = session.status == ScheduledSessionStatus.canceled;
    final isUpcoming = session.status == ScheduledSessionStatus.upcoming;
    final isGoing =
        session.viewerRsvpStatus == ScheduledSessionRsvpStatus.going ||
        session.createdById == viewerId;

    final children = <Widget>[];

    if (isUpcoming && !isCanceled) {
      children.add(
        Wrap(
          spacing: AscendSpacing.sm,
          runSpacing: AscendSpacing.sm,
          children: [
            for (final option in const [
              (ScheduledSessionRsvpStatus.going, 'Going'),
              (ScheduledSessionRsvpStatus.maybe, 'Maybe'),
              (ScheduledSessionRsvpStatus.declined, "Can't go"),
            ])
              ChoiceChip(
                label: Text(option.$2),
                selected: session.viewerRsvpStatus == option.$1,
                onSelected: isActing
                    ? null
                    : (selected) {
                        if (selected) {
                          controller.rsvp(option.$1);
                        } else {
                          controller.cancelRsvp();
                        }
                      },
              ),
          ],
        ),
      );
      if (session.viewerRsvpStatus != null) {
        children.add(
          TextButton(
            onPressed: isActing ? null : controller.cancelRsvp,
            child: const Text('Clear my RSVP'),
          ),
        );
      }
    }

    if (session.jointWorkoutSessionId != null && !isCanceled) {
      if (isGoing) {
        children.add(
          FilledButton(
            onPressed: isActing
                ? null
                : () => _joinSession(context, controller),
            child: const Text('Join session'),
          ),
        );
      }
    } else if (canManage && isUpcoming && !isCanceled) {
      children.add(
        FilledButton(
          onPressed: isActing ? null : () => _startSession(context, controller),
          child: const Text('Start session'),
        ),
      );
    }

    if (canManage && !isCanceled) {
      children.add(
        TextButton(
          onPressed: isActing ? null : controller.cancelSession,
          child: const Text('Cancel session'),
        ),
      );
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final child in children)
          Padding(
            padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
            child: child,
          ),
      ],
    );
  }

  Future<void> _startSession(
    BuildContext context,
    ScheduledSessionDetailController controller,
  ) async {
    final liveSessionId = await controller.startSession();
    if (liveSessionId == null || !context.mounted) return;
    context.push(RoutePaths.jointWorkoutDetailPath(liveSessionId));
  }

  Future<void> _joinSession(
    BuildContext context,
    ScheduledSessionDetailController controller,
  ) async {
    final liveSessionId = await controller.joinSession();
    if (liveSessionId == null || !context.mounted) return;
    context.push(RoutePaths.jointWorkoutDetailPath(liveSessionId));
  }
}
