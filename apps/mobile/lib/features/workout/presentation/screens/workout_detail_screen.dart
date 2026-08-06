import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/exercise.dart';
import '../../domain/workout.dart';
import '../providers/workout_catalog_controller.dart';
import '../providers/workout_plan_controller.dart';
import '../providers/workout_session_controller.dart';

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  const WorkoutDetailScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  ConsumerState<WorkoutDetailScreen> createState() =>
      _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  bool _isStarting = false;

  Future<void> _start(Workout workout) async {
    setState(() => _isStarting = true);
    try {
      final plan = await ref
          .read(workoutPlanRepositoryProvider)
          .createFromWorkout(name: workout.name, workoutId: workout.id);
      await ref
          .read(workoutSessionControllerProvider.notifier)
          .start(workoutPlanId: plan.id, workoutPlanName: plan.name);
      if (!mounted) return;
      context.push(RoutePaths.workoutPlayer);
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutAsync = ref.watch(
      workoutCatalogDetailProvider(widget.workoutId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Workout')),
      body: SafeArea(
        child: workoutAsync.when(
          data: (workout) => Column(
            children: [
              Expanded(child: _WorkoutDetailBody(workout: workout)),
              Padding(
                padding: const EdgeInsets.all(AscendSpacing.md),
                child: AscendPrimaryButton(
                  label: 'Start Workout',
                  icon: Icons.play_arrow_rounded,
                  isLoading: _isStarting,
                  onPressed: () => _start(workout),
                ),
              ),
            ],
          ),
          loading: () => const AscendLoadingIndicator(),
          error: (error, stackTrace) => AscendEmptyState(
            icon: Icons.cloud_off_outlined,
            title: "Couldn't load this workout",
            message: 'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () =>
                ref.invalidate(workoutCatalogDetailProvider(widget.workoutId)),
          ),
        ),
      ),
    );
  }
}

class _WorkoutDetailBody extends StatelessWidget {
  const _WorkoutDetailBody({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AscendSpacing.md),
      children: [
        Text(workout.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AscendSpacing.xs),
        Wrap(
          spacing: AscendSpacing.xs,
          children: [
            Chip(label: Text(workout.category.name)),
            Chip(label: Text(exerciseDifficultyLabel(workout.difficulty))),
            Chip(label: Text('${workout.estimatedDurationMinutes} min')),
          ],
        ),
        const SizedBox(height: AscendSpacing.md),
        Text(workout.description, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AscendSpacing.lg),
        Text('Exercises', style: theme.textTheme.titleMedium),
        const SizedBox(height: AscendSpacing.sm),
        for (final entry in workout.exercises)
          Padding(
            padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
            child: AscendCard(
              child: Row(
                children: [
                  CircleAvatar(radius: 16, child: Text('${entry.order}')),
                  const SizedBox(width: AscendSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.exercise.name,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          _targetLabel(entry),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _targetLabel(PrescribedExercise entry) {
    final parts = <String>['${entry.targetSets} sets'];
    if (entry.targetReps != null) parts.add('${entry.targetReps} reps');
    if (entry.targetDurationSeconds != null) {
      parts.add('${entry.targetDurationSeconds}s');
    }
    if (entry.targetWeightKg != null) parts.add('${entry.targetWeightKg} kg');
    return parts.join(' · ');
  }
}
