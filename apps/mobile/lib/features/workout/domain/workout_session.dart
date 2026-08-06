import 'exercise_substitution.dart';

enum WorkoutSessionStatus { inProgress, paused, completed, abandoned }

WorkoutSessionStatus workoutSessionStatusFromJson(String value) =>
    WorkoutSessionStatus.values.firstWhere(
      (e) =>
          e.name.toUpperCase().replaceAll('_', '') == value.replaceAll('_', ''),
      orElse: () => WorkoutSessionStatus.inProgress,
    );

String workoutSessionStatusToJson(WorkoutSessionStatus status) {
  switch (status) {
    case WorkoutSessionStatus.inProgress:
      return 'IN_PROGRESS';
    case WorkoutSessionStatus.paused:
      return 'PAUSED';
    case WorkoutSessionStatus.completed:
      return 'COMPLETED';
    case WorkoutSessionStatus.abandoned:
      return 'ABANDONED';
  }
}

/// One logged set. `serverId` is null until this specific set has been
/// pushed to the backend — the sync step uses that to know which sets in
/// an otherwise-synced session still need pushing.
class LoggedSet {
  const LoggedSet({
    required this.localId,
    required this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    required this.completedAt,
    this.serverId,
    this.reps,
    this.weightKg,
    this.durationSeconds,
    this.distanceMeters,
    this.isWarmup = false,
    this.rpe,
  });

  final String localId;
  final String? serverId;
  final String exerciseId;
  final String exerciseName;
  final int setNumber;
  final int? reps;
  final double? weightKg;
  final int? durationSeconds;
  final double? distanceMeters;
  final bool isWarmup;
  final DateTime completedAt;

  /// Optional perceived-exertion rating for this set, 1–10 (half-point
  /// increments allowed). Purely informational to the athlete and to
  /// history — see `packages/docs/architecture.md`'s progression section
  /// for why this is never fed into automatic load suggestions.
  final double? rpe;

  bool get isSynced => serverId != null;

  LoggedSet copyWith({String? serverId}) {
    return LoggedSet(
      localId: localId,
      serverId: serverId ?? this.serverId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      setNumber: setNumber,
      reps: reps,
      weightKg: weightKg,
      durationSeconds: durationSeconds,
      distanceMeters: distanceMeters,
      isWarmup: isWarmup,
      completedAt: completedAt,
      rpe: rpe,
    );
  }

  Map<String, dynamic> toCacheJson() => {
    'localId': localId,
    'serverId': serverId,
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'setNumber': setNumber,
    'reps': reps,
    'weightKg': weightKg,
    'durationSeconds': durationSeconds,
    'distanceMeters': distanceMeters,
    'isWarmup': isWarmup,
    'completedAt': completedAt.toIso8601String(),
    'rpe': rpe,
  };

  factory LoggedSet.fromCacheJson(Map<String, dynamic> json) {
    return LoggedSet(
      localId: json['localId'] as String,
      serverId: json['serverId'] as String?,
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      setNumber: json['setNumber'] as int,
      reps: json['reps'] as int?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      durationSeconds: json['durationSeconds'] as int?,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      isWarmup: json['isWarmup'] as bool? ?? false,
      completedAt: DateTime.parse(json['completedAt'] as String),
      rpe: (json['rpe'] as num?)?.toDouble(),
    );
  }

  factory LoggedSet.fromApiJson(Map<String, dynamic> json) {
    final exercise = json['exercise'] as Map<String, dynamic>;
    return LoggedSet(
      localId: json['id'] as String,
      serverId: json['id'] as String,
      exerciseId: exercise['id'] as String,
      exerciseName: exercise['name'] as String,
      setNumber: json['setNumber'] as int,
      reps: json['reps'] as int?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      durationSeconds: json['durationSeconds'] as int?,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      isWarmup: json['isWarmup'] as bool? ?? false,
      completedAt: DateTime.parse(json['completedAt'] as String),
      rpe: (json['rpe'] as num?)?.toDouble(),
    );
  }
}

enum SessionSyncStatus { synced, pending, failed }

/// The single local-first source of truth for the workout player: this is
/// what the UI renders, what gets persisted to Drift after every mutation
/// (so an app kill mid-workout resumes cleanly), and what a background sync
/// pass tries to reconcile with the backend. See
/// packages/docs/architecture.md for the synchronization strategy this
/// implements.
class WorkoutSessionState {
  const WorkoutSessionState({
    required this.localId,
    required this.userId,
    required this.status,
    required this.startedAt,
    required this.resumedAt,
    required this.activeDurationSeconds,
    required this.sets,
    this.serverId,
    this.workoutPlanId,
    this.workoutPlanName,
    this.pausedAt,
    this.completedAt,
    this.syncStatus = SessionSyncStatus.pending,
    this.syncError,
    this.difficultyRating,
    this.substitutions = const [],
  });

  final String localId;
  final String? serverId;
  final String userId;
  final String? workoutPlanId;
  final String? workoutPlanName;
  final WorkoutSessionStatus status;
  final DateTime startedAt;
  final DateTime resumedAt;
  final DateTime? pausedAt;
  final DateTime? completedAt;
  final int activeDurationSeconds;
  final List<LoggedSet> sets;
  final SessionSyncStatus syncStatus;
  final String? syncError;
  final List<ExerciseSubstitution> substitutions;

  /// Optional 1–10 "how hard did the whole session feel" rating, captured
  /// once at finish time. Stored here (not just passed straight through to
  /// the finish call) so a finish that happens offline still replays with
  /// the rating attached once sync succeeds.
  final int? difficultyRating;

  bool get isActive =>
      status == WorkoutSessionStatus.inProgress ||
      status == WorkoutSessionStatus.paused;

  /// The exercise a *new* set for [exerciseId] should actually be logged
  /// against — the active substitution's target if one exists, otherwise
  /// [exerciseId] unchanged. Mirrors the backend's own redirect lookup in
  /// `WorkoutSessionsService.logSet`, so the two stay in agreement even if
  /// this substitution hasn't synced yet.
  ExerciseSubstitution? activeSubstitutionFor(String exerciseId) {
    for (final substitution in substitutions.reversed) {
      if (substitution.originalExerciseId == exerciseId) return substitution;
    }
    return null;
  }

  /// Live elapsed active seconds, accounting for time since the last
  /// resume when currently in progress.
  int liveActiveDurationSeconds({DateTime? now}) {
    if (status != WorkoutSessionStatus.inProgress) return activeDurationSeconds;
    final clock = now ?? DateTime.now();
    final sinceResume = clock.difference(resumedAt).inSeconds;
    return activeDurationSeconds + (sinceResume < 0 ? 0 : sinceResume);
  }

  WorkoutSessionState copyWith({
    String? serverId,
    WorkoutSessionStatus? status,
    DateTime? resumedAt,
    Object? pausedAt = _unset,
    Object? completedAt = _unset,
    int? activeDurationSeconds,
    List<LoggedSet>? sets,
    SessionSyncStatus? syncStatus,
    Object? syncError = _unset,
    Object? difficultyRating = _unset,
    List<ExerciseSubstitution>? substitutions,
  }) {
    return WorkoutSessionState(
      localId: localId,
      serverId: serverId ?? this.serverId,
      userId: userId,
      workoutPlanId: workoutPlanId,
      workoutPlanName: workoutPlanName,
      status: status ?? this.status,
      startedAt: startedAt,
      resumedAt: resumedAt ?? this.resumedAt,
      pausedAt: pausedAt == _unset ? this.pausedAt : pausedAt as DateTime?,
      completedAt: completedAt == _unset
          ? this.completedAt
          : completedAt as DateTime?,
      activeDurationSeconds:
          activeDurationSeconds ?? this.activeDurationSeconds,
      sets: sets ?? this.sets,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError == _unset ? this.syncError : syncError as String?,
      difficultyRating: difficultyRating == _unset
          ? this.difficultyRating
          : difficultyRating as int?,
      substitutions: substitutions ?? this.substitutions,
    );
  }

  Map<String, dynamic> toCacheJson() => {
    'localId': localId,
    'serverId': serverId,
    'userId': userId,
    'workoutPlanId': workoutPlanId,
    'workoutPlanName': workoutPlanName,
    'status': workoutSessionStatusToJson(status),
    'startedAt': startedAt.toIso8601String(),
    'resumedAt': resumedAt.toIso8601String(),
    'pausedAt': pausedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'activeDurationSeconds': activeDurationSeconds,
    'sets': sets.map((s) => s.toCacheJson()).toList(),
    'syncStatus': syncStatus.name,
    'syncError': syncError,
    'difficultyRating': difficultyRating,
    'substitutions': substitutions.map((s) => s.toCacheJson()).toList(),
  };

  factory WorkoutSessionState.fromCacheJson(Map<String, dynamic> json) {
    return WorkoutSessionState(
      localId: json['localId'] as String,
      serverId: json['serverId'] as String?,
      userId: json['userId'] as String,
      workoutPlanId: json['workoutPlanId'] as String?,
      workoutPlanName: json['workoutPlanName'] as String?,
      status: workoutSessionStatusFromJson(json['status'] as String),
      startedAt: DateTime.parse(json['startedAt'] as String),
      resumedAt: DateTime.parse(json['resumedAt'] as String),
      pausedAt: json['pausedAt'] == null
          ? null
          : DateTime.parse(json['pausedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      activeDurationSeconds: json['activeDurationSeconds'] as int,
      sets: (json['sets'] as List<dynamic>? ?? [])
          .map((s) => LoggedSet.fromCacheJson(s as Map<String, dynamic>))
          .toList(),
      difficultyRating: json['difficultyRating'] as int?,
      substitutions: (json['substitutions'] as List<dynamic>? ?? [])
          .map(
            (s) => ExerciseSubstitution.fromCacheJson(s as Map<String, dynamic>),
          )
          .toList(),
      syncStatus: SessionSyncStatus.values.firstWhere(
        (s) => s.name == json['syncStatus'],
        orElse: () => SessionSyncStatus.pending,
      ),
      syncError: json['syncError'] as String?,
    );
  }
}

const _unset = Object();
