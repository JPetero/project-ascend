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
    this.description,
    this.archivedAt,
  });

  final String id;
  final String name;
  final String? description;
  final WorkoutPlanSummary? workout;
  final List<PrescribedExercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;
  bool get isCustom => workout == null;

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
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
      archivedAt: json['archivedAt'] == null
          ? null
          : DateTime.parse(json['archivedAt'] as String),
    );
  }
}
