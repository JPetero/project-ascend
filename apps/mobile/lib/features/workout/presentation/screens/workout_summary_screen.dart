import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/personal_record.dart';
import '../providers/workout_session_controller.dart';

class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  const WorkoutSummaryScreen({super.key, required this.result});

  final WorkoutFinishResult result;

  @override
  ConsumerState<WorkoutSummaryScreen> createState() =>
      _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen> {
  late WorkoutFinishResult _result = widget.result;
  bool _isRetrying = false;

  Future<void> _retry() async {
    setState(() => _isRetrying = true);
    final result = await ref
        .read(workoutSessionControllerProvider.notifier)
        .retrySync(_result.session);
    if (!mounted) return;
    setState(() {
      _result = result;
      _isRetrying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = _result.session;
    final nonWarmupSets = session.sets.where((s) => !s.isWarmup).toList();
    final exerciseCount = nonWarmupSets.map((s) => s.exerciseId).toSet().length;
    final totalVolume = nonWarmupSets
        .where((s) => s.reps != null && s.weightKg != null)
        .fold<double>(0, (sum, s) => sum + s.reps! * s.weightKg!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Summary'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          children: [
            const Icon(
              Icons.check_circle,
              color: AscendColors.successEmerald,
              size: 56,
            ),
            const SizedBox(height: AscendSpacing.md),
            Text(
              'Nice work!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AscendSpacing.lg),
            if (!_result.synced)
              _SyncBanner(isRetrying: _isRetrying, onRetry: _retry),
            if (!_result.synced) const SizedBox(height: AscendSpacing.md),
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
                  value: _formatDuration(session.activeDurationSeconds),
                  icon: Icons.timer_outlined,
                ),
                AscendMetricCard(
                  label: 'Exercises',
                  value: '$exerciseCount',
                  icon: Icons.fitness_center_rounded,
                ),
                AscendMetricCard(
                  label: 'Sets',
                  value: '${nonWarmupSets.length}',
                  icon: Icons.format_list_numbered,
                ),
                AscendMetricCard(
                  label: 'Volume',
                  value: '${totalVolume.toStringAsFixed(0)} kg',
                  icon: Icons.bar_chart_rounded,
                ),
              ],
            ),
            if (_result.newPersonalRecords.isNotEmpty) ...[
              const SizedBox(height: AscendSpacing.lg),
              Text(
                'New personal records!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AscendSpacing.sm),
              for (final record in _result.newPersonalRecords)
                Padding(
                  padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
                  child: _PersonalRecordCelebration(record: record),
                ),
            ],
            const SizedBox(height: AscendSpacing.lg),
            AscendPrimaryButton(
              label: 'Done',
              onPressed: () => context.go(RoutePaths.workout),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.isRetrying, required this.onRetry});

  final bool isRetrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AscendCard(
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, color: theme.colorScheme.error),
          const SizedBox(width: AscendSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved on this device only',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  "We'll keep trying, or tap retry now.",
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AscendSpacing.sm),
          AscendSecondaryButton(
            label: 'Retry',
            expand: false,
            isLoading: isRetrying,
            onPressed: isRetrying ? null : onRetry,
          ),
        ],
      ),
    );
  }
}

class _PersonalRecordCelebration extends StatelessWidget {
  const _PersonalRecordCelebration({required this.record});

  final PersonalRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AscendCard(
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: AscendColors.premiumGold),
          const SizedBox(width: AscendSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.exercise.name, style: theme.textTheme.titleSmall),
                Text(
                  '${personalRecordTypeLabel(record.type)}: ${record.value} ${record.unit}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
