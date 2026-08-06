import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/workout_history_entry.dart';
import '../providers/workout_history_controller.dart';

class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: SafeArea(
        child: historyAsync.when(
          data: (entries) => entries.isEmpty
              ? const AscendEmptyState(
                  icon: Icons.history,
                  title: 'No workouts yet',
                  message: 'Finish a workout to see it here.',
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(workoutHistoryListProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AscendSpacing.md),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AscendSpacing.sm,
                        ),
                        child: _HistoryRow(entry: entry),
                      );
                    },
                  ),
                ),
          loading: () => const AscendLoadingIndicator(),
          error: (error, stackTrace) => AscendEmptyState(
            icon: Icons.cloud_off_outlined,
            title: "Couldn't load your history",
            message: 'Pull to refresh to try again.',
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final WorkoutHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = entry.completedAt ?? entry.startedAt;

    return AscendCard(
      onTap: () => context.push(RoutePaths.workoutHistoryDetailPath(entry.id)),
      semanticLabel: entry.workoutPlan?.name ?? 'Workout',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.workoutPlan?.name ?? 'Workout',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AscendSpacing.xs),
                Text(
                  '${_formatDate(date)} · ${entry.setCount} sets · '
                  '${entry.exerciseCount} exercises',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour < 12 ? 'AM' : 'PM';
  return '${_months[date.month - 1]} ${date.day}, ${date.year}, $hour:$minute $period';
}
