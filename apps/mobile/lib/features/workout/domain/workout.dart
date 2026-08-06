import 'exercise.dart';

/// One prescribed exercise within a catalog [Workout] or a user's
/// [WorkoutPlan] — the same shape either way, just sourced from a different
/// endpoint, which is why it isn't split into two near-identical classes.
class PrescribedExercise {
  const PrescribedExercise({
    required this.id,
    required this.order,
    required this.targetSets,
    required this.exercise,
    this.targetReps,
    this.targetDurationSeconds,
    this.targetWeightKg,
    this.restSeconds = 60,
    this.notes,
  });

  final String id;
  final int order;
  final int targetSets;
  final int? targetReps;
  final int? targetDurationSeconds;
  final double? targetWeightKg;
  final int restSeconds;
  final String? notes;
  final ExerciseSummary exercise;

  factory PrescribedExercise.fromJson(Map<String, dynamic> json) {
    return PrescribedExercise(
      id: json['id'] as String,
      order: json['order'] as int,
      targetSets: json['targetSets'] as int,
      targetReps: json['targetReps'] as int?,
      targetDurationSeconds: json['targetDurationSeconds'] as int?,
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
      restSeconds: json['restSeconds'] as int? ?? 60,
      notes: json['notes'] as String?,
      exercise: ExerciseSummary.fromJson(
        json['exercise'] as Map<String, dynamic>,
      ),
    );
  }
}

/// A curated, shared catalog workout (not user-owned) — what "Browse
/// workouts" lists. Starting one creates a personal [WorkoutPlan] copy.
class Workout {
  const Workout({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.difficulty,
    required this.estimatedDurationMinutes,
    required this.category,
    required this.exercises,
  });

  final String id;
  final String name;
  final String slug;
  final String description;
  final ExerciseDifficulty difficulty;
  final int estimatedDurationMinutes;
  final ExerciseCategory category;
  final List<PrescribedExercise> exercises;

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String,
      difficulty: exerciseDifficultyFromJson(json['difficulty'] as String),
      estimatedDurationMinutes: json['estimatedDurationMinutes'] as int,
      category: ExerciseCategory.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map((e) => PrescribedExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
