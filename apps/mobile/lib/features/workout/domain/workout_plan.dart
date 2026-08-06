import 'workout.dart';

class WorkoutPlanSummary {
  const WorkoutPlanSummary({required this.id, required this.name});

  final String id;
  final String name;

  factory WorkoutPlanSummary.fromJson(Map<String, dynamic> json) {
    return WorkoutPlanSummary(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

/// A user's own workout plan — either started from a catalog [Workout]
/// (copied in, then freely editable) or built from scratch.
class WorkoutPlan {
  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
    this.workout,
  });

  final String id;
  final String name;
  final WorkoutPlanSummary? workout;
  final List<PrescribedExercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      workout: json['workout'] == null
          ? null
          : WorkoutPlanSummary.fromJson(
              json['workout'] as Map<String, dynamic>,
            ),
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map((e) => PrescribedExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
