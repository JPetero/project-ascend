import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/trainer_group.dart';
import '../providers/trainer_dashboard_provider.dart';

/// Trainer Dashboard (Build Session 12 Part 11) — a read-only overview
/// of every group the caller owns or moderates: member counts, pending
/// assignments, upcoming scheduled sessions, and recent assignments
/// across the whole roster. A caller who owns/moderates nothing sees an
/// honest empty state rather than a locked/upsell screen — this isn't a
/// Premium feature, just nothing to show yet.
class TrainerDashboardScreen extends ConsumerWidget {
  const TrainerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(trainerDashboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trainer dashboard')),
      body: SafeArea(
        child: dashboard.when(
          loading: () => const AscendLoadingIndicator(),
          error: (error, stackTrace) => AscendEmptyState(
            icon: Icons.error_outline,
            title: "Couldn't load the dashboard",
            message: error.toString(),
          ),
          data: (data) {
            if (data.groups.isEmpty) {
              return const AscendEmptyState(
                icon: Icons.dashboard_outlined,
                title: 'Nothing to show yet',
                message:
                    'Own or moderate a Trainer Group to see it summarized here.',
              );
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  ref.refresh(trainerDashboardProvider.future),
              child: ListView(
                padding: const EdgeInsets.all(AscendSpacing.md),
                children: [
                  Text(
                    'Assignments',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AscendSpacing.sm),
                  AscendCard(
                    child: Wrap(
                      spacing: AscendSpacing.md,
                      runSpacing: AscendSpacing.sm,
                      children: [
                        _CountChip(
                          label: 'Assigned',
                          count: data.assignmentCounts.assigned,
                        ),
                        _CountChip(
                          label: 'Accepted',
                          count: data.assignmentCounts.accepted,
                        ),
                        _CountChip(
                          label: 'Declined',
                          count: data.assignmentCounts.declined,
                        ),
                        _CountChip(
                          label: 'Completed',
                          count: data.assignmentCounts.completed,
                        ),
                        _CountChip(
                          label: 'Overdue',
                          count: data.assignmentCounts.overdue,
                          isAlert: data.assignmentCounts.overdue > 0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AscendSpacing.lg),
                  Text(
                    'Your groups',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AscendSpacing.sm),
                  for (final group in data.groups)
                    AscendCard(
                      onTap: () => context.push(
                        RoutePaths.trainerGroupDetailPath(group.id),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  '${group.memberCount} member'
                                  '${group.memberCount == 1 ? '' : 's'}'
                                  '${group.pendingAssignmentCount > 0 ? ' · ${group.pendingAssignmentCount} pending assignment${group.pendingAssignmentCount == 1 ? '' : 's'}' : ''}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  const SizedBox(height: AscendSpacing.lg),
                  Text(
                    'Upcoming scheduled sessions',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AscendSpacing.sm),
                  if (data.upcomingSessions.isEmpty)
                    const Text('Nothing scheduled.')
                  else
                    for (final session in data.upcomingSessions)
                      AscendCard(
                        child: ListTile(
                          title: Text(session.title ?? 'Group session'),
                          subtitle: Text(
                            session.scheduledAt.toLocal().toString(),
                          ),
                        ),
                      ),
                  const SizedBox(height: AscendSpacing.lg),
                  Text(
                    'Recent assignments',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AscendSpacing.sm),
                  if (data.recentAssignments.isEmpty)
                    const Text('Nothing assigned yet.')
                  else
                    for (final assignment in data.recentAssignments)
                      AscendCard(
                        child: ListTile(
                          title: Text(assignment.sourcePlanName),
                          subtitle: Text(_statusLabel(assignment.status)),
                        ),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _statusLabel(WorkoutAssignmentStatus status) {
    switch (status) {
      case WorkoutAssignmentStatus.pending:
        return 'Pending';
      case WorkoutAssignmentStatus.accepted:
        return 'In progress';
      case WorkoutAssignmentStatus.declined:
        return 'Declined';
      case WorkoutAssignmentStatus.completed:
        return 'Completed';
      case WorkoutAssignmentStatus.canceled:
        return 'Canceled';
    }
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.count,
    this.isAlert = false,
  });

  final String label;
  final int count;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isAlert ? Theme.of(context).colorScheme.error : null,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
