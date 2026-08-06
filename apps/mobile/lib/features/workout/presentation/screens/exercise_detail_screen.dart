import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/exercise.dart';
import '../providers/exercise_controller.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseDetailProvider(exerciseId));

    return Scaffold(
      appBar: AppBar(title: const Text('Exercise')),
      body: SafeArea(
        child: exerciseAsync.when(
          data: (exercise) => _ExerciseDetailBody(exercise: exercise),
          loading: () => const AscendLoadingIndicator(),
          error: (error, stackTrace) => AscendEmptyState(
            icon: Icons.cloud_off_outlined,
            title: "Couldn't load this exercise",
            message: 'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(exerciseDetailProvider(exerciseId)),
          ),
        ),
      ),
    );
  }
}

class _ExerciseDetailBody extends StatelessWidget {
  const _ExerciseDetailBody({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AscendSpacing.md),
      children: [
        const _MediaPlaceholder(),
        const SizedBox(height: AscendSpacing.md),
        Text(exercise.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AscendSpacing.xs),
        Wrap(
          spacing: AscendSpacing.xs,
          children: [
            Chip(label: Text(exercise.category.name)),
            Chip(label: Text(exerciseDifficultyLabel(exercise.difficulty))),
          ],
        ),
        const SizedBox(height: AscendSpacing.md),
        Text(exercise.description, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AscendSpacing.lg),
        if (exercise.primaryMuscles.isNotEmpty) ...[
          _Section(
            title: 'Primary muscles',
            child: _MuscleChips(
              muscles: exercise.primaryMuscles,
              emphasized: true,
            ),
          ),
          const SizedBox(height: AscendSpacing.md),
        ],
        if (exercise.secondaryMuscles.isNotEmpty) ...[
          _Section(
            title: 'Secondary muscles',
            child: _MuscleChips(
              muscles: exercise.secondaryMuscles,
              emphasized: false,
            ),
          ),
          const SizedBox(height: AscendSpacing.md),
        ],
        if (exercise.equipment.isNotEmpty) ...[
          _Section(
            title: 'Equipment',
            child: Wrap(
              spacing: AscendSpacing.xs,
              children: [
                for (final e in exercise.equipment) Chip(label: Text(e.name)),
              ],
            ),
          ),
          const SizedBox(height: AscendSpacing.md),
        ],
        _Section(
          title: 'Instructions',
          child: Text(exercise.instructions, style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(height: AscendSpacing.md),
        _Section(
          title: 'Safety tips',
          icon: Icons.shield_outlined,
          child: Text(exercise.safetyTips, style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(height: AscendSpacing.md),
        _Section(
          title: 'Common mistakes',
          icon: Icons.warning_amber_rounded,
          child: Text(
            exercise.commonMistakes,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        if (exercise.alternatives.isNotEmpty) ...[
          const SizedBox(height: AscendSpacing.md),
          _Section(
            title: 'Alternatives',
            child: Column(
              children: [
                for (final alt in exercise.alternatives)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
                    child: AscendCard(
                      onTap: () => context.pushReplacement(
                        RoutePaths.exerciseDetailPath(alt.id),
                      ),
                      semanticLabel: alt.name,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              alt.name,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.icon});

  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AscendSpacing.xs),
            ],
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: AscendSpacing.sm),
        child,
      ],
    );
  }
}

class _MuscleChips extends StatelessWidget {
  const _MuscleChips({required this.muscles, required this.emphasized});

  final List<MuscleGroup> muscles;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AscendSpacing.xs,
      children: [
        for (final muscle in muscles)
          Chip(
            label: Text(muscle.name),
            backgroundColor: emphasized ? colorScheme.primaryContainer : null,
          ),
      ],
    );
  }
}

/// No real media pipeline exists yet (see packages/docs/roadmap.md) — this
/// is an honest placeholder, not a broken image.
class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: AscendRadius.largeRadius,
      child: Container(
        height: 160,
        width: double.infinity,
        color: colorScheme.surfaceContainerHighest,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              color: colorScheme.onSurfaceVariant,
              size: 32,
            ),
            const SizedBox(height: AscendSpacing.xs),
            Text(
              'Photo & video coming soon',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
