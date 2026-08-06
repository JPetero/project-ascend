import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/exercise.dart';
import '../providers/exercise_controller.dart';

const _categoryFilters = [
  (label: 'All', slug: null),
  (label: 'Strength', slug: 'strength'),
  (label: 'Cardio', slug: 'cardio'),
  (label: 'Mobility', slug: 'mobility'),
  (label: 'Bodyweight', slug: 'bodyweight'),
  (label: 'Recovery', slug: 'recovery'),
];

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseLibraryControllerProvider);
    final controller = ref.read(exerciseLibraryControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Library')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AscendSpacing.md,
                AscendSpacing.md,
                AscendSpacing.md,
                AscendSpacing.sm,
              ),
              child: AscendTextField(
                label: 'Search exercises',
                controller: _searchController,
                suffixIcon: const Icon(Icons.search),
                onChanged: controller.search,
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AscendSpacing.md,
                ),
                children: [
                  for (final filter in _categoryFilters)
                    Padding(
                      padding: const EdgeInsets.only(right: AscendSpacing.sm),
                      child: ChoiceChip(
                        label: Text(filter.label),
                        selected: controller.categorySlug == filter.slug,
                        onSelected: (_) =>
                            controller.filterByCategory(filter.slug),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AscendSpacing.sm),
            Expanded(
              child: exercisesAsync.when(
                data: (exercises) => exercises.isEmpty
                    ? const AscendEmptyState(
                        icon: Icons.search_off,
                        title: 'No exercises found',
                        message: 'Try a different search or category.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AscendSpacing.md,
                        ),
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = exercises[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AscendSpacing.sm,
                            ),
                            child: _ExerciseRow(exercise: exercise),
                          );
                        },
                      ),
                loading: () => const AscendLoadingIndicator(),
                error: (error, stackTrace) => AscendEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: "Couldn't load exercises",
                  message: 'Check your connection and try again.',
                  actionLabel: 'Retry',
                  onAction: controller.load,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AscendCard(
      onTap: () => context.push(RoutePaths.exerciseDetailPath(exercise.id)),
      semanticLabel: exercise.name,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: AscendSpacing.xs),
                Text(
                  [
                    if (exercise.primaryMuscles.isNotEmpty)
                      exercise.primaryMuscles.map((m) => m.name).join(', '),
                    exerciseDifficultyLabel(exercise.difficulty),
                  ].join(' · '),
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
