import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/trainer_groups_repository.dart';
import '../../domain/trainer_group.dart';
import 'trainer_groups_controller.dart';

class MyAssignmentsState {
  const MyAssignmentsState({
    this.assignments = const [],
    this.isLoading = true,
    this.error,
  });

  final List<WorkoutAssignment> assignments;
  final bool isLoading;
  final String? error;

  MyAssignmentsState copyWith({
    List<WorkoutAssignment>? assignments,
    bool? isLoading,
    String? error,
  }) {
    return MyAssignmentsState(
      assignments: assignments ?? this.assignments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Backs the "Assigned workouts" screen reachable from the dashboard
/// (Build Session 12 Part 9) — a member's own to-do list across every
/// trainer group they belong to. Deliberately separate from
/// `TrainerGroupDetailController`'s group-scoped assignment list, which
/// only owners/moderators can see.
class MyAssignmentsController extends StateNotifier<MyAssignmentsState> {
  MyAssignmentsController({required TrainerGroupsRepository repository})
    : _repository = repository,
      super(const MyAssignmentsState()) {
    refresh();
  }

  final TrainerGroupsRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final assignments = await _repository.listMyAssignments();
      state = MyAssignmentsState(assignments: assignments, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  /// Returns the new workout plan's id on success, so the caller can
  /// offer to jump straight to it — `null` on failure.
  Future<String?> accept(String assignmentId) async {
    try {
      final workoutPlanId = await _repository.acceptAssignment(assignmentId);
      await refresh();
      return workoutPlanId;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return null;
    }
  }

  Future<bool> dismiss(String assignmentId) async {
    final previous = state.assignments;
    state = state.copyWith(
      assignments: previous.where((a) => a.id != assignmentId).toList(),
    );
    try {
      await _repository.cancelAssignment(assignmentId);
      return true;
    } catch (error) {
      state = state.copyWith(assignments: previous, error: error.toString());
      return false;
    }
  }

  /// Declines a still-pending assignment (Build Session 13 Part 4) —
  /// replaces it in place with status declined rather than removing it,
  /// since the server keeps the row for the trainer dashboard's counts.
  Future<bool> decline(String assignmentId) async {
    try {
      final updated = await _repository.declineAssignment(assignmentId);
      state = state.copyWith(
        assignments: state.assignments
            .map((a) => a.id == updated.id ? updated : a)
            .toList(),
      );
      return true;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return false;
    }
  }
}

final myAssignmentsControllerProvider =
    StateNotifierProvider<MyAssignmentsController, MyAssignmentsState>((ref) {
      return MyAssignmentsController(
        repository: ref.watch(trainerGroupsRepositoryProvider),
      );
    });
