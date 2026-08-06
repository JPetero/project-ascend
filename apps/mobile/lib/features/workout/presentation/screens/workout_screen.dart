import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/app_shell.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/exercise.dart';
import '../../domain/workout.dart';
import '../../domain/workout_session.dart';
import '../providers/workout_catalog_controller.dart';
import '../providers/workout_session_controller.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(workoutSessionControllerProvider);
    final workoutsAsync = ref.watch(workoutCatalogListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add_check_outlined),
            tooltip: 'My plans',
            onPressed: () => context.push(RoutePaths.myWorkoutPlans),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: 'Personal records',
            onPressed: () => context.push(RoutePaths.personalRecords),
          ),
          IconButton(
            icon: const Icon(Icons.military_tech_outlined),
            tooltip: 'Achievements',
            onPressed: () => context.push(RoutePaths.achievements),
          ),
          IconButton(
            icon: const Icon(Icons.directions_run_outlined),
            tooltip: 'Cardio',
            onPressed: () => context.push(RoutePaths.cardioHistory),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => context.push(RoutePaths.workoutHistory),
          ),
          const ProfileIconAction(),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(workoutCatalogListProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(AscendSpacing.md),
            children: [
              if (activeSession != null && activeSession.isActive) ...[
                _ActiveSessionBanner(session: activeSession),
                const SizedBox(height: AscendSpacing.lg),
              ],
              AscendSectionHeader(
                title: 'Browse workouts',
                subtitle:
                    'Pick a workout to start, or explore the exercise library.',
                actionLabel: 'Exercises',
                onAction: () => context.push(RoutePaths.exerciseLibrary),
              ),
              const SizedBox(height: AscendSpacing.md),
              workoutsAsync.when(
                data: (workouts) => workouts.isEmpty
                    ? const AscendEmptyState(
                        icon: Icons.fitness_center_outlined,
                        title: 'No workouts yet',
                        message: 'Check back soon for curated workouts.',
                      )
                    : Column(
                        children: [
                          for (final workout in workouts) ...[
                            _WorkoutCard(workout: workout),
                            const SizedBox(height: AscendSpacing.sm),
                          ],
                        ],
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AscendSpacing.xl),
                  child: AscendLoadingIndicator(),
                ),
                error: (error, stackTrace) => AscendEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: "Couldn't load workouts",
                  message: 'Pull to refresh to try again.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveSessionBanner extends StatelessWidget {
  const _ActiveSessionBanner({required this.session});

  final WorkoutSessionState session;

  @override
  Widget build(BuildContext context) {
    final isPaused = session.status == WorkoutSessionStatus.paused;

    return AscendCard(
      onTap: () => context.push(RoutePaths.workoutPlayer),
      semanticLabel: 'Resume your in-progress workout',
      child: Row(
        children: [
          Icon(
            isPaused
                ? Icons.pause_circle_outline
                : Icons.fitness_center_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AscendSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPaused ? 'Workout paused' : 'Workout in progress',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  session.workoutPlanName ?? 'Tap to resume',
                  style: Theme.of(context).textTheme.bodyMedium,
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

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AscendCard(
      onTap: () => context.push(RoutePaths.workoutDetailPath(workout.id)),
      semanticLabel: workout.name,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(workout.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: AscendSpacing.xs),
                Text(
                  '${workout.category.name} · ${workout.estimatedDurationMinutes} min · '
                  '${exerciseDifficultyLabel(workout.difficulty)}',
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
