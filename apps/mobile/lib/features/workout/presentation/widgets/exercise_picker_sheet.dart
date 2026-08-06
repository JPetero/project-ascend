import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/exercise.dart';
import '../providers/exercise_controller.dart';

/// Search/filter the exercise library and pick one to add to a plan.
Future<ExerciseSummary?> showExercisePickerSheet(BuildContext context) {
  return showAscendBottomSheet<ExerciseSummary>(
    context: context,
    title: 'Add an exercise',
    child: const _ExercisePickerContent(),
  );
}

class _ExercisePickerContent extends ConsumerStatefulWidget {
  const _ExercisePickerContent();

  @override
  ConsumerState<_ExercisePickerContent> createState() =>
      _ExercisePickerContentState();
}

class _ExercisePickerContentState
    extends ConsumerState<_ExercisePickerContent> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(exerciseLibraryControllerProvider);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AscendTextField(
            label: 'Search exercises',
            controller: _searchController,
            onChanged: (value) => ref
                .read(exerciseLibraryControllerProvider.notifier)
                .search(value),
          ),
          const SizedBox(height: AscendSpacing.md),
          Expanded(
            child: resultsAsync.when(
              data: (exercises) => exercises.isEmpty
                  ? const AscendEmptyState(
                      icon: Icons.search_off_outlined,
                      title: 'No matching exercises',
                      message: 'Try a different search term.',
                    )
                  : ListView.builder(
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AscendSpacing.sm,
                          ),
                          child: AscendCard(
                            onTap: () => Navigator.of(context).pop(
                              ExerciseSummary(
                                id: exercise.id,
                                name: exercise.name,
                                slug: exercise.slug,
                                difficulty: exercise.difficulty,
                                category: exercise.category,
                              ),
                            ),
                            semanticLabel: 'Add ${exercise.name}',
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exercise.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      Text(
                                        exercise.category.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.add_circle_outline),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              loading: () => const AscendLoadingIndicator(),
              error: (error, stackTrace) => const AscendEmptyState(
                icon: Icons.cloud_off_outlined,
                title: "Couldn't load exercises",
                message: 'Check your connection and try again.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
