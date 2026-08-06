import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/plan_exercise_draft.dart';
import '../../domain/workout_plan.dart';
import '../providers/workout_plan_controller.dart';
import '../providers/workout_plan_editor_service.dart';
import '../widgets/exercise_picker_sheet.dart';
import '../widgets/plan_exercise_target_sheet.dart';

/// Create-or-edit form for a custom workout plan. Passing [planId] loads
/// and pre-fills an existing plan (including one duplicated or started
/// from a catalog Workout — both are just plans once created); omitting it
/// starts a blank draft.
class WorkoutPlanEditorScreen extends ConsumerStatefulWidget {
  const WorkoutPlanEditorScreen({super.key, this.planId});

  final String? planId;

  @override
  ConsumerState<WorkoutPlanEditorScreen> createState() =>
      _WorkoutPlanEditorScreenState();
}

class _WorkoutPlanEditorScreenState
    extends ConsumerState<WorkoutPlanEditorScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<PlanExerciseDraft> _exercises = [];
  bool _isSaving = false;
  bool _loadedExisting = false;

  bool get _isEditing => widget.planId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadFrom(WorkoutPlan plan) {
    if (_loadedExisting) return;
    _loadedExisting = true;
    _nameController.text = plan.name;
    _descriptionController.text = plan.description ?? '';
    _exercises.addAll(plan.exercises.map(PlanExerciseDraft.fromPrescribed));
  }

  Future<void> _addExercise() async {
    final chosen = await showExercisePickerSheet(context);
    if (chosen == null) return;
    setState(() => _exercises.add(PlanExerciseDraft.fromExercise(chosen)));
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give this plan a name first.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final exercisesJson = [
      for (var i = 0; i < _exercises.length; i++) _exercises[i].toJson(i + 1),
    ];
    final description = _descriptionController.text.trim();

    try {
      final service = ref.read(workoutPlanEditorServiceProvider);
      final bool savedImmediately;
      if (_isEditing) {
        savedImmediately = await service.updatePlan(
          id: widget.planId!,
          name: name,
          description: description.isEmpty ? null : description,
          exercises: exercisesJson,
        );
      } else {
        savedImmediately = await service.createPlan(
          name: name,
          description: description.isEmpty ? null : description,
          exercises: exercisesJson,
        );
      }

      await ref.read(myWorkoutPlansControllerProvider.notifier).load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedImmediately
                ? 'Plan saved.'
                : "You're offline — this plan will save once you're back online.",
          ),
        ),
      );
      context.pop();
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = _isEditing
        ? ref.watch(workoutPlanDetailProvider(widget.planId!))
        : null;

    if (planAsync != null) {
      return planAsync.when(
        data: (plan) {
          _loadFrom(plan);
          return _buildScaffold(context);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit Plan')),
          body: const AscendLoadingIndicator(),
        ),
        error: (error, stackTrace) => Scaffold(
          appBar: AppBar(title: const Text('Edit Plan')),
          body: AscendEmptyState(
            icon: Icons.cloud_off_outlined,
            title: "Couldn't load this plan",
            message: 'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () =>
                ref.invalidate(workoutPlanDetailProvider(widget.planId!)),
          ),
        ),
      );
    }

    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Plan' : 'New Plan'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          children: [
            AscendTextField(label: 'Plan name', controller: _nameController),
            const SizedBox(height: AscendSpacing.sm),
            AscendTextField(
              label: 'Description (optional)',
              controller: _descriptionController,
            ),
            const SizedBox(height: AscendSpacing.lg),
            AscendSectionHeader(
              title: 'Exercises',
              actionLabel: 'Add',
              onAction: _addExercise,
            ),
            const SizedBox(height: AscendSpacing.sm),
            if (_exercises.isEmpty)
              const AscendEmptyState(
                icon: Icons.fitness_center_outlined,
                title: 'No exercises yet',
                message: 'Tap Add to build out this plan.',
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _exercises.length,
                onReorderItem: (oldIndex, newIndex) {
                  setState(() {
                    final item = _exercises.removeAt(oldIndex);
                    _exercises.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final draft = _exercises[index];
                  return _PlanExerciseTile(
                    key: ValueKey('${draft.exerciseId}-$index'),
                    draft: draft,
                    onEdit: () async {
                      await showPlanExerciseTargetSheet(context, draft);
                      if (mounted) setState(() {});
                    },
                    onRemove: () => setState(() => _exercises.removeAt(index)),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanExerciseTile extends StatelessWidget {
  const _PlanExerciseTile({
    super.key,
    required this.draft,
    required this.onEdit,
    required this.onRemove,
  });

  final PlanExerciseDraft draft;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final parts = <String>['${draft.targetSets} sets'];
    if (draft.targetReps != null) parts.add('${draft.targetReps} reps');
    if (draft.targetDurationSeconds != null) {
      parts.add('${draft.targetDurationSeconds}s');
    }
    if (draft.targetWeightKg != null) parts.add('${draft.targetWeightKg} kg');
    if (draft.targetDistanceMeters != null) {
      parts.add('${draft.targetDistanceMeters}m');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
      child: AscendCard(
        onTap: onEdit,
        semanticLabel: 'Edit targets for ${draft.exerciseName}',
        child: Row(
          children: [
            const Icon(Icons.drag_handle),
            const SizedBox(width: AscendSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft.exerciseName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    parts.join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Remove',
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
