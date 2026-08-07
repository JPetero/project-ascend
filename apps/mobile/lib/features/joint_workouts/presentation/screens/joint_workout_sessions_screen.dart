import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../friends/presentation/providers/friends_controller.dart';
import '../../domain/joint_workout_session.dart';
import '../providers/joint_workout_sessions_controller.dart';

/// Friend-only joint workout sessions home — Build Session 8 Part 9.
/// Reachable from the Community tab, mirroring Trainer Groups' and
/// Friends' own entry points.
class JointWorkoutSessionsScreen extends ConsumerWidget {
  const JointWorkoutSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(jointWorkoutSessionsControllerProvider);
    final controller = ref.read(
      jointWorkoutSessionsControllerProvider.notifier,
    );
    // Loaded eagerly (rather than only when the create dialog opens) so
    // the friend list is already populated by the time someone taps the
    // FAB, instead of racing the fetch.
    ref.watch(friendsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Joint Workouts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        tooltip: 'Start a session',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: state.isLoading
            ? const AscendLoadingIndicator()
            : state.sessions.isEmpty
            ? const AscendEmptyState(
                icon: Icons.group_work_outlined,
                title: 'No joint workouts yet',
                message:
                    'Invite a friend to train together in real time — you '
                    'both choose your own exercises and loads.',
              )
            : RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.all(AscendSpacing.md),
                  itemCount: state.sessions.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AscendSpacing.sm),
                  itemBuilder: (context, index) {
                    final session = state.sessions[index];
                    return AscendCard(
                      onTap: () => context.push(
                        RoutePaths.jointWorkoutDetailPath(session.id),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.title ?? 'Joint workout',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  '${session.participants.length} participants · '
                                  '${_statusLabel(session.status)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final friends = ref.read(friendsControllerProvider).friends;
    final selected = <String>{};

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Start a joint workout'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AscendTextField(
                  label: 'Title (optional)',
                  controller: titleController,
                ),
                const SizedBox(height: AscendSpacing.md),
                if (friends.isEmpty)
                  const Text('Add friends first to invite them.')
                else ...[
                  const Text('Invite friends'),
                  for (final friend in friends)
                    CheckboxListTile(
                      value: selected.contains(friend.userId),
                      title: Text(friend.displayName),
                      onChanged: (checked) => setState(() {
                        if (checked == true) {
                          selected.add(friend.userId);
                        } else {
                          selected.remove(friend.userId);
                        }
                      }),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );

    if (created != true) return;
    final session = await ref
        .read(jointWorkoutSessionsControllerProvider.notifier)
        .create(
          title: titleController.text.trim().isEmpty
              ? null
              : titleController.text.trim(),
          inviteeIds: selected.toList(),
        );
    if (session != null && context.mounted) {
      context.push(RoutePaths.jointWorkoutDetailPath(session.id));
    }
  }

  String _statusLabel(JointWorkoutSessionStatus status) {
    switch (status) {
      case JointWorkoutSessionStatus.created:
        return 'Not started';
      case JointWorkoutSessionStatus.inProgress:
        return 'In progress';
      case JointWorkoutSessionStatus.finished:
        return 'Finished';
      case JointWorkoutSessionStatus.canceled:
        return 'Canceled';
    }
  }
}
