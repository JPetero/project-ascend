import 'workout_plan.dart';
import 'workout_session.dart';

class HistorySubstitutionExercise {
  const HistorySubstitutionExercise({required this.id, required this.name});

  final String id;
  final String name;

  factory HistorySubstitutionExercise.fromJson(Map<String, dynamic> json) {
    return HistorySubstitutionExercise(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class HistorySubstitution {
  const HistorySubstitution({
    required this.id,
    required this.originalExercise,
    required this.substituteExercise,
  });

  final String id;
  final HistorySubstitutionExercise originalExercise;
  final HistorySubstitutionExercise substituteExercise;

  factory HistorySubstitution.fromJson(Map<String, dynamic> json) {
    return HistorySubstitution(
      id: json['id'] as String,
      originalExercise: HistorySubstitutionExercise.fromJson(
        json['originalExercise'] as Map<String, dynamic>,
      ),
      substituteExercise: HistorySubstitutionExercise.fromJson(
        json['substituteExercise'] as Map<String, dynamic>,
      ),
    );
  }
}

class WorkoutHistoryEntry {
  const WorkoutHistoryEntry({
    required this.id,
    required this.startedAt,
    required this.activeDurationSeconds,
    required this.exerciseCount,
    required this.setCount,
    required this.totalVolumeKg,
    this.workoutPlan,
    this.completedAt,
  });

  final String id;
  final WorkoutPlanSummary? workoutPlan;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int activeDurationSeconds;
  final int exerciseCount;
  final int setCount;
  final double totalVolumeKg;

  factory WorkoutHistoryEntry.fromJson(Map<String, dynamic> json) {
    return WorkoutHistoryEntry(
      id: json['id'] as String,
      workoutPlan: json['workoutPlan'] == null
          ? null
          : WorkoutPlanSummary.fromJson(
              json['workoutPlan'] as Map<String, dynamic>,
            ),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      activeDurationSeconds: json['activeDurationSeconds'] as int,
      exerciseCount: json['exerciseCount'] as int,
      setCount: json['setCount'] as int,
      totalVolumeKg: (json['totalVolumeKg'] as num).toDouble(),
    );
  }
}

class WorkoutHistoryDetail extends WorkoutHistoryEntry {
  const WorkoutHistoryDetail({
    required super.id,
    required super.startedAt,
    required super.activeDurationSeconds,
    required super.exerciseCount,
    required super.setCount,
    required super.totalVolumeKg,
    required this.sets,
    super.workoutPlan,
    super.completedAt,
    this.notes,
    this.difficultyRating,
    this.substitutions = const [],
  });

  final List<LoggedSet> sets;
  final String? notes;
  final int? difficultyRating;
  final List<HistorySubstitution> substitutions;

  factory WorkoutHistoryDetail.fromJson(Map<String, dynamic> json) {
    return WorkoutHistoryDetail(
      id: json['id'] as String,
      workoutPlan: json['workoutPlan'] == null
          ? null
          : WorkoutPlanSummary.fromJson(
              json['workoutPlan'] as Map<String, dynamic>,
            ),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      activeDurationSeconds: json['activeDurationSeconds'] as int,
      exerciseCount: json['exerciseCount'] as int,
      setCount: json['setCount'] as int,
      totalVolumeKg: (json['totalVolumeKg'] as num).toDouble(),
      notes: json['notes'] as String?,
      difficultyRating: json['difficultyRating'] as int?,
      sets: (json['sets'] as List<dynamic>? ?? [])
          .map((s) => LoggedSet.fromApiJson(s as Map<String, dynamic>))
          .toList(),
      substitutions: (json['substitutions'] as List<dynamic>? ?? [])
          .map((s) => HistorySubstitution.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
