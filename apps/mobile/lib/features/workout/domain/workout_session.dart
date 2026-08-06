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

  bool get isActive =>
      status == WorkoutSessionStatus.inProgress ||
      status == WorkoutSessionStatus.paused;

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
      syncStatus: SessionSyncStatus.values.firstWhere(
        (s) => s.name == json['syncStatus'],
        orElse: () => SessionSyncStatus.pending,
      ),
      syncError: json['syncError'] as String?,
    );
  }
}

const _unset = Object();
