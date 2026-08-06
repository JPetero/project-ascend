import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/workout_history_entry.dart';
import '../../domain/workout_session.dart';
import '../providers/workout_history_controller.dart';

class WorkoutHistoryDetailScreen extends ConsumerWidget {
  const WorkoutHistoryDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(workoutHistoryDetailProvider(sessionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Details')),
      body: SafeArea(
        child: detailAsync.when(
          data: (detail) => _DetailBody(detail: detail),
          loading: () => const AscendLoadingIndicator(),
          error: (error, stackTrace) => AscendEmptyState(
            icon: Icons.cloud_off_outlined,
            title: "Couldn't load this workout",
            message: 'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () =>
                ref.invalidate(workoutHistoryDetailProvider(sessionId)),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final WorkoutHistoryDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byExercise = <String, List<LoggedSet>>{};
    for (final set in detail.sets) {
      byExercise.putIfAbsent(set.exerciseName, () => []).add(set);
    }

    return ListView(
      padding: const EdgeInsets.all(AscendSpacing.md),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AscendSpacing.md,
          crossAxisSpacing: AscendSpacing.md,
          childAspectRatio: 1.6,
          children: [
            AscendMetricCard(
              label: 'Duration',
              value: _formatDuration(detail.activeDurationSeconds),
              icon: Icons.timer_outlined,
            ),
            AscendMetricCard(
              label: 'Volume',
              value: '${detail.totalVolumeKg.toStringAsFixed(0)} kg',
              icon: Icons.bar_chart_rounded,
            ),
          ],
        ),
        if (detail.difficultyRating != null) ...[
          const SizedBox(height: AscendSpacing.md),
          AscendMetricCard(
            label: 'Session effort (RPE)',
            value: '${detail.difficultyRating}/10',
            icon: Icons.speed_outlined,
          ),
        ],
        if (detail.substitutions.isNotEmpty) ...[
          const SizedBox(height: AscendSpacing.lg),
          Text('Substitutions', style: theme.textTheme.titleMedium),
          const SizedBox(height: AscendSpacing.sm),
          for (final substitution in detail.substitutions)
            Padding(
              padding: const EdgeInsets.only(bottom: AscendSpacing.xs),
              child: Text(
                '${substitution.originalExercise.name} → ${substitution.substituteExercise.name}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
        ],
        const SizedBox(height: AscendSpacing.lg),
        for (final exerciseName in byExercise.keys) ...[
          Text(exerciseName, style: theme.textTheme.titleMedium),
          const SizedBox(height: AscendSpacing.sm),
          for (final set in byExercise[exerciseName]!)
            Padding(
              padding: const EdgeInsets.only(bottom: AscendSpacing.xs),
              child: Text(
                'Set ${set.setNumber}: ${_describeSet(set)}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: AscendSpacing.md),
        ],
      ],
    );
  }

  String _describeSet(LoggedSet set) {
    final parts = <String>[];
    if (set.weightKg != null) parts.add('${set.weightKg} kg');
    if (set.reps != null) parts.add('${set.reps} reps');
    if (set.durationSeconds != null) parts.add('${set.durationSeconds}s');
    if (set.distanceMeters != null) parts.add('${set.distanceMeters}m');
    if (set.rpe != null) parts.add('RPE ${set.rpe}');
    return parts.join(' × ');
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
  }
}
