import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/workout_plan.dart';
import '../providers/workout_plan_controller.dart';

class MyWorkoutPlansScreen extends ConsumerWidget {
  const MyWorkoutPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(myWorkoutPlansControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Plans')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RoutePaths.workoutPlanEditorNew),
        tooltip: 'New plan',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(myWorkoutPlansControllerProvider.notifier).load(),
          child: plansAsync.when(
            data: (plans) {
              if (plans.isEmpty) {
                return ListView(
                  children: const [
                    SizedBox(height: 80),
                    AscendEmptyState(
                      icon: Icons.playlist_add_outlined,
                      title: 'No plans yet',
                      message: 'Tap + to build your first custom plan.',
                    ),
                  ],
                );
              }
              final active = plans.where((p) => !p.isArchived).toList();
              final archived = plans.where((p) => p.isArchived).toList();
              return ListView(
                padding: const EdgeInsets.all(AscendSpacing.md),
                children: [
                  for (final plan in active) _PlanTile(plan: plan),
                  if (archived.isNotEmpty) ...[
                    const SizedBox(height: AscendSpacing.lg),
                    Text(
                      'Archived',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AscendSpacing.sm),
                    for (final plan in archived) _PlanTile(plan: plan),
                  ],
                ],
              );
            },
            loading: () => const AscendLoadingIndicator(),
            error: (error, stackTrace) => AscendEmptyState(
              icon: Icons.cloud_off_outlined,
              title: "Couldn't load your plans",
              message: 'Pull to refresh to try again.',
              actionLabel: 'Retry',
              onAction: () =>
                  ref.read(myWorkoutPlansControllerProvider.notifier).load(),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanTile extends ConsumerWidget {
  const _PlanTile({required this.plan});

  final WorkoutPlan plan;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this plan?'),
        content: Text('"${plan.name}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          AscendDangerButton(
            label: 'Delete',
            expand: false,
            onPressed: () => context.pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(myWorkoutPlansControllerProvider.notifier).delete(plan.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
      child: Opacity(
        opacity: plan.isArchived ? 0.6 : 1,
        child: AscendCard(
          onTap: () =>
              context.push(RoutePaths.workoutPlanEditorEditPath(plan.id)),
          semanticLabel: plan.name,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AscendSpacing.xs),
                    Text(
                      '${plan.exercises.length} exercise${plan.exercises.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (action) async {
                  final notifier = ref.read(
                    myWorkoutPlansControllerProvider.notifier,
                  );
                  switch (action) {
                    case 'duplicate':
                      await notifier.duplicate(plan);
                    case 'archive':
                      await notifier.archive(plan.id);
                    case 'unarchive':
                      await notifier.unarchive(plan.id);
                    case 'delete':
                      await _confirmDelete(context, ref);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Text('Duplicate'),
                  ),
                  if (plan.isArchived)
                    const PopupMenuItem(
                      value: 'unarchive',
                      child: Text('Unarchive'),
                    )
                  else
                    const PopupMenuItem(
                      value: 'archive',
                      child: Text('Archive'),
                    ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
