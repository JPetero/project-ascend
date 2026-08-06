/// A single active substitution within a session: sets logged against
/// [originalExerciseId] after this point should be recorded as
/// [substituteExerciseId] instead. Already-logged [LoggedSet]s keep
/// whatever exercise id they were logged with — this record only affects
/// what happens *next*, mirroring the backend's
/// `WorkoutSessionSubstitution` redirect model.
class ExerciseSubstitution {
  const ExerciseSubstitution({
    required this.localId,
    required this.originalExerciseId,
    required this.originalExerciseName,
    required this.substituteExerciseId,
    required this.substituteExerciseName,
    this.serverId,
  });

  final String localId;
  final String? serverId;
  final String originalExerciseId;
  final String originalExerciseName;
  final String substituteExerciseId;
  final String substituteExerciseName;

  bool get isSynced => serverId != null;

  ExerciseSubstitution copyWith({String? serverId}) => ExerciseSubstitution(
    localId: localId,
    serverId: serverId ?? this.serverId,
    originalExerciseId: originalExerciseId,
    originalExerciseName: originalExerciseName,
    substituteExerciseId: substituteExerciseId,
    substituteExerciseName: substituteExerciseName,
  );

  Map<String, dynamic> toCacheJson() => {
    'localId': localId,
    'serverId': serverId,
    'originalExerciseId': originalExerciseId,
    'originalExerciseName': originalExerciseName,
    'substituteExerciseId': substituteExerciseId,
    'substituteExerciseName': substituteExerciseName,
  };

  factory ExerciseSubstitution.fromCacheJson(Map<String, dynamic> json) {
    return ExerciseSubstitution(
      localId: json['localId'] as String,
      serverId: json['serverId'] as String?,
      originalExerciseId: json['originalExerciseId'] as String,
      originalExerciseName: json['originalExerciseName'] as String,
      substituteExerciseId: json['substituteExerciseId'] as String,
      substituteExerciseName: json['substituteExerciseName'] as String,
    );
  }
}
