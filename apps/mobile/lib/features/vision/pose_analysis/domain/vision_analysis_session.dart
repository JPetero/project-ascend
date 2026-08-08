import 'form_observation.dart';
import 'supported_exercise.dart';

String supportedExerciseToJson(SupportedExercise exercise) {
  switch (exercise) {
    case SupportedExercise.bodyweightSquat:
      return 'BODYWEIGHT_SQUAT';
    case SupportedExercise.bicepsCurl:
      return 'BICEPS_CURL';
    case SupportedExercise.shoulderPress:
      return 'SHOULDER_PRESS';
  }
}

SupportedExercise supportedExerciseFromJson(String value) {
  switch (value) {
    case 'BICEPS_CURL':
      return SupportedExercise.bicepsCurl;
    case 'SHOULDER_PRESS':
      return SupportedExercise.shoulderPress;
    case 'BODYWEIGHT_SQUAT':
    default:
      return SupportedExercise.bodyweightSquat;
  }
}

String formObservationSeverityToJson(FormObservationSeverity severity) {
  switch (severity) {
    case FormObservationSeverity.info:
      return 'INFO';
    case FormObservationSeverity.coachingCue:
      return 'COACHING_CUE';
    case FormObservationSeverity.checkForm:
      return 'CHECK_FORM';
  }
}

FormObservationSeverity formObservationSeverityFromJson(String value) {
  switch (value) {
    case 'CHECK_FORM':
      return FormObservationSeverity.checkForm;
    case 'COACHING_CUE':
      return FormObservationSeverity.coachingCue;
    case 'INFO':
    default:
      return FormObservationSeverity.info;
  }
}

/// A saved Vision analysis result (Build Session 10 Part 6) — the
/// server-persisted counterpart to [LiveVisionSessionState] once a
/// session ends and the user chooses to save it. `PoseConfidence` never
/// crosses this boundary (it's a live per-frame concept); this model
/// only carries what's actually meaningful after the fact.
class VisionAnalysisSession {
  const VisionAnalysisSession({
    required this.id,
    required this.exercise,
    required this.startedAt,
    required this.completedAt,
    required this.autoRepCount,
    required this.correctedRepCount,
    required this.analysisVersion,
    required this.observations,
    this.mediaAssetId,
    this.workoutSessionId,
    required this.createdAt,
  });

  final String id;
  final SupportedExercise exercise;
  final DateTime startedAt;
  final DateTime completedAt;
  final int autoRepCount;
  final int correctedRepCount;
  final String analysisVersion;
  final List<FormObservation> observations;
  final String? mediaAssetId;
  final String? workoutSessionId;
  final DateTime createdAt;

  factory VisionAnalysisSession.fromJson(Map<String, dynamic> json) {
    return VisionAnalysisSession(
      id: json['id'] as String,
      exercise: supportedExerciseFromJson(json['exercise'] as String),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: DateTime.parse(json['completedAt'] as String),
      autoRepCount: json['autoRepCount'] as int,
      correctedRepCount: json['correctedRepCount'] as int,
      analysisVersion: json['analysisVersion'] as String,
      observations: (json['observations'] as List<dynamic>? ?? [])
          .map((o) => _observationFromJson(o as Map<String, dynamic>))
          .toList(),
      mediaAssetId: json['mediaAssetId'] as String?,
      workoutSessionId: json['workoutSessionId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static FormObservation _observationFromJson(Map<String, dynamic> json) {
    return FormObservation(
      type: json['type'] as String,
      message: json['message'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      severity: formObservationSeverityFromJson(json['severity'] as String),
      timestamp: DateTime.parse(json['occurredAt'] as String),
    );
  }
}
