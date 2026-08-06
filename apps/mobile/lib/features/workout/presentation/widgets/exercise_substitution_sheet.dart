import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/exercise.dart';
import '../providers/exercise_controller.dart';

/// Opens the substitution flow for [currentExerciseId] and, if the user
/// confirms a replacement, returns the chosen [ExerciseSummary]. Returns
/// null if the sheet was dismissed without a choice.
Future<ExerciseSummary?> showExerciseSubstitutionSheet({
  required BuildContext context,
  required String currentExerciseId,
  required String currentExerciseName,
}) {
  return showAscendBottomSheet<ExerciseSummary>(
    context: context,
    title: 'Substitute $currentExerciseName',
    child: _ExerciseSubstitutionContent(currentExerciseId: currentExerciseId),
  );
}

class _ExerciseSubstitutionContent extends ConsumerStatefulWidget {
  const _ExerciseSubstitutionContent({required this.currentExerciseId});

  final String currentExerciseId;

  @override
  ConsumerState<_ExerciseSubstitutionContent> createState() =>
      _ExerciseSubstitutionContentState();
}

class _ExerciseSubstitutionContentState
    extends ConsumerState<_ExerciseSubstitutionContent> {
  final _searchController = TextEditingController();
  String? _expandedCandidateId;
  List<Exercise>? _searchResults;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await ref
          .read(exerciseRepositoryProvider)
          .list(search: trimmed);
      if (!mounted) return;
      setState(() {
        _searchResults = results
            .where((e) => e.id != widget.currentExerciseId)
            .toList();
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      exerciseDetailProvider(widget.currentExerciseId),
    );

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AscendTextField(
            label: 'Search the exercise library',
            controller: _searchController,
            onChanged: _runSearch,
          ),
          const SizedBox(height: AscendSpacing.md),
          Expanded(
            child: _searchController.text.trim().isNotEmpty
                ? _buildSearchResults()
                : detailAsync.when(
                    data: (exercise) => _buildCurated(exercise),
                    loading: () => const AscendLoadingIndicator(),
                    error: (error, stackTrace) => const AscendEmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: "Couldn't load alternatives",
                      message: 'Check your connection and try again.',
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) return const AscendLoadingIndicator();
    final results = _searchResults ?? const [];
    if (results.isEmpty) {
      return const AscendEmptyState(
        icon: Icons.search_off_outlined,
        title: 'No matching exercises',
        message: 'Try a different search term.',
      );
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final exercise = results[index];
        return _CandidateTile(
          candidate: ExerciseSummary(
            id: exercise.id,
            name: exercise.name,
            slug: exercise.slug,
            difficulty: exercise.difficulty,
            category: exercise.category,
          ),
          isExpanded: _expandedCandidateId == exercise.id,
          onToggle: () => setState(
            () => _expandedCandidateId =
                _expandedCandidateId == exercise.id ? null : exercise.id,
          ),
          onConfirm: () => Navigator.of(context).pop(
            ExerciseSummary(
              id: exercise.id,
              name: exercise.name,
              slug: exercise.slug,
              difficulty: exercise.difficulty,
              category: exercise.category,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurated(Exercise exercise) {
    if (exercise.alternatives.isEmpty) {
      return const AscendEmptyState(
        icon: Icons.swap_horiz_outlined,
        title: 'No suggested alternatives yet',
        message: 'Search the library above to find a replacement.',
      );
    }
    return ListView.builder(
      itemCount: exercise.alternatives.length,
      itemBuilder: (context, index) {
        final candidate = exercise.alternatives[index];
        return _CandidateTile(
          candidate: candidate,
          isExpanded: _expandedCandidateId == candidate.id,
          onToggle: () => setState(
            () => _expandedCandidateId =
                _expandedCandidateId == candidate.id ? null : candidate.id,
          ),
          onConfirm: () => Navigator.of(context).pop(candidate),
        );
      },
    );
  }
}

class _CandidateTile extends ConsumerWidget {
  const _CandidateTile({
    required this.candidate,
    required this.isExpanded,
    required this.onToggle,
    required this.onConfirm,
  });

  final ExerciseSummary candidate;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
      child: AscendCard(
        onTap: onToggle,
        semanticLabel: 'View details for ${candidate.name}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(candidate.name, style: theme.textTheme.titleMedium),
                      if (candidate.category != null)
                        Text(
                          candidate.category!.name,
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                AscendSecondaryButton(
                  label: 'Use this',
                  expand: false,
                  onPressed: onConfirm,
                ),
              ],
            ),
            if (isExpanded) _CandidateDetails(exerciseId: candidate.id),
          ],
        ),
      ),
    );
  }
}

class _CandidateDetails extends ConsumerWidget {
  const _CandidateDetails({required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(exerciseDetailProvider(exerciseId));
    return Padding(
      padding: const EdgeInsets.only(top: AscendSpacing.sm),
      child: detailAsync.when(
        data: (exercise) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            Text(
              'Primary muscles: ${exercise.primaryMuscles.map((m) => m.name).join(', ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AscendSpacing.xs),
            Text(
              'Measured by: ${measurementTypeLabel(exercise.measurementType)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AscendSpacing.sm),
          child: AscendLoadingIndicator(),
        ),
        error: (error, stackTrace) => Text(
          "Couldn't load details.",
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
