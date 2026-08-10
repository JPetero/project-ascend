import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/trainer_group.dart';
import '../providers/my_assignments_controller.dart';

/// A member's own to-do list of workouts a trainer assigned them,
/// across every group they belong to (Build Session 12 Part 9).
/// Accepting clones the trainer's plan into the member's own workout
/// plans — see MyAssignmentsController.accept — after which the
/// assignment resolves itself automatically the moment a session
/// against that plan is finished; there is no "mark done" button here.
class MyAssignmentsScreen extends ConsumerWidget {
  const MyAssignmentsScreen({super.key});

  String _statusLabel(WorkoutAssignmentStatus status) {
    switch (status) {
      case WorkoutAssignmentStatus.pending:
        return 'New';
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

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    WorkoutAssignment assignment,
  ) async {
    final workoutPlanId = await ref
        .read(myAssignmentsControllerProvider.notifier)
        .accept(assignment.id);
    if (!context.mounted) return;
    if (workoutPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't accept — try again.")),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to your workout plans.'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () =>
              context.push(RoutePaths.workoutPlanEditorEditPath(workoutPlanId)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myAssignmentsControllerProvider);
    final controller = ref.read(myAssignmentsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Assigned workouts')),
      body: SafeArea(
        child: state.isLoading
            ? const AscendLoadingIndicator()
            : RefreshIndicator(
                onRefresh: controller.refresh,
                child: state.assignments.isEmpty
                    ? ListView(
                        children: const [
                          AscendEmptyState(
                            icon: Icons.assignment_ind_outlined,
                            title: 'Nothing assigned yet',
                            message:
                                "When a trainer assigns you a workout, it'll show up here.",
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.all(AscendSpacing.md),
                        children: [
                          for (final assignment in state.assignments)
                            AscendCard(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          assignment.sourcePlanName,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                        Text(
                                          assignment.isOverdue
                                              ? 'Overdue'
                                              : _statusLabel(assignment.status),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: assignment.isOverdue
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.error
                                                    : null,
                                              ),
                                        ),
                                        if (assignment.dueAt != null)
                                          Text(
                                            'Due ${assignment.dueAt!.toLocal().toString().split(' ').first}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        if (assignment.note != null)
                                          Text(
                                            assignment.note!,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (assignment.status ==
                                      WorkoutAssignmentStatus.pending) ...[
                                    TextButton(
                                      onPressed: () =>
                                          controller.decline(assignment.id),
                                      child: const Text('Decline'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          _accept(context, ref, assignment),
                                      child: const Text('Accept'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
      ),
    );
  }
}
