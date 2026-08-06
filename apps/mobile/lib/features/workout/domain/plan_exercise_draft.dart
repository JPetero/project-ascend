import 'exercise.dart';
import 'workout.dart';

/// A mutable row in the plan editor's exercise list — separate from
/// [PrescribedExercise] (an immutable API-shaped read model) since the
/// editor needs to freely reorder, edit, and remove rows before anything
/// is saved. `order` is derived from list position at save time, not
/// tracked here.
class PlanExerciseDraft {
  PlanExerciseDraft({
    required this.exerciseId,
    required this.exerciseName,
    required this.targetSets,
    this.targetReps,
    this.targetDurationSeconds,
    this.targetWeightKg,
    this.targetDistanceMeters,
    this.restSeconds = 60,
    this.notes,
  });

  factory PlanExerciseDraft.fromPrescribed(PrescribedExercise entry) {
    return PlanExerciseDraft(
      exerciseId: entry.exercise.id,
      exerciseName: entry.exercise.name,
      targetSets: entry.targetSets,
      targetReps: entry.targetReps,
      targetDurationSeconds: entry.targetDurationSeconds,
      targetWeightKg: entry.targetWeightKg,
      targetDistanceMeters: entry.targetDistanceMeters,
      restSeconds: entry.restSeconds,
      notes: entry.notes,
    );
  }

  factory PlanExerciseDraft.fromExercise(ExerciseSummary exercise) {
    return PlanExerciseDraft(
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      targetSets: 3,
    );
  }

  final String exerciseId;
  final String exerciseName;
  int targetSets;
  int? targetReps;
  int? targetDurationSeconds;
  double? targetWeightKg;
  double? targetDistanceMeters;
  int restSeconds;
  String? notes;

  Map<String, dynamic> toJson(int order) => {
    'exerciseId': exerciseId,
    'order': order,
    'targetSets': targetSets,
    if (targetReps != null) 'targetReps': targetReps,
    if (targetDurationSeconds != null)
      'targetDurationSeconds': targetDurationSeconds,
    if (targetWeightKg != null) 'targetWeightKg': targetWeightKg,
    if (targetDistanceMeters != null)
      'targetDistanceMeters': targetDistanceMeters,
    'restSeconds': restSeconds,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
  };
}
