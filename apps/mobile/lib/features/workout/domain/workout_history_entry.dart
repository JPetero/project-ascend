import 'workout_plan.dart';
import 'workout_session.dart';

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
  });

  final List<LoggedSet> sets;
  final String? notes;

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
      sets: (json['sets'] as List<dynamic>? ?? [])
          .map((s) => LoggedSet.fromApiJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
