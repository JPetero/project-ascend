import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/workout_plan_repository.dart';
import '../../domain/plan_exercise_draft.dart';
import '../../domain/workout_plan.dart';

final workoutPlanRepositoryProvider = Provider<WorkoutPlanRepository>((ref) {
  return WorkoutPlanRepository(apiClient: ref.watch(apiClientProvider));
});

final workoutPlanDetailProvider = FutureProvider.autoDispose
    .family<WorkoutPlan, String>((ref, id) {
      return ref.watch(workoutPlanRepositoryProvider).getById(id);
    });

/// The signed-in user's own plans (custom or copied-from-catalog),
/// including archived ones — "My Plans" filters client-side by
/// [WorkoutPlan.isArchived] rather than round-tripping for each toggle.
class MyWorkoutPlansController extends StateNotifier<AsyncValue<List<WorkoutPlan>>> {
  MyWorkoutPlansController({required WorkoutPlanRepository repository})
    : _repository = repository,
      super(const AsyncValue.loading()) {
    load();
  }

  final WorkoutPlanRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final plans = await _repository.list(includeArchived: true);
      state = AsyncValue.data(plans);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> archive(String id) async {
    await _repository.archive(id);
    await load();
  }

  Future<void> unarchive(String id) async {
    await _repository.unarchive(id);
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await load();
  }

  /// Copies [source]'s exercises into a brand-new plan named "Copy of X".
  Future<WorkoutPlan> duplicate(WorkoutPlan source) async {
    final drafts = source.exercises
        .map(PlanExerciseDraft.fromPrescribed)
        .toList();
    final result = await _repository.create(
      name: 'Copy of ${source.name}',
      description: source.description,
      exercises: [
        for (var i = 0; i < drafts.length; i++) drafts[i].toJson(i + 1),
      ],
    );
    await load();
    return WorkoutPlan.fromJson(result);
  }
}

final myWorkoutPlansControllerProvider =
    StateNotifierProvider<MyWorkoutPlansController, AsyncValue<List<WorkoutPlan>>>((
      ref,
    ) {
      return MyWorkoutPlansController(
        repository: ref.watch(workoutPlanRepositoryProvider),
      );
    });
