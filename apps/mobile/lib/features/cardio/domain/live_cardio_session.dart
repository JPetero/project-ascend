import 'cardio_session.dart';

enum LiveCardioStatus { tracking, paused }

/// The state of an in-progress (or paused, not-yet-uploaded) live-GPS
/// cardio session. Immutable, like `WorkoutSessionState` — every mutation
/// in `LiveCardioSessionController` produces a new instance and persists
/// it via `AppDatabase.cacheLiveCardioSession`, which is what makes
/// interrupted-session recovery possible.
class LiveCardioSessionState {
  const LiveCardioSessionState({
    required this.localId,
    required this.userId,
    required this.activityType,
    required this.status,
    required this.startedAt,
    required this.resumedAt,
    this.pausedAt,
    required this.activeDurationSeconds,
    required this.distanceMeters,
    required this.routePoints,
    this.lastFixAt,
    this.pausedForBackground = false,
  });

  final String localId;
  final String userId;
  final CardioActivityType activityType;
  final LiveCardioStatus status;
  final DateTime startedAt;
  // The wall-clock moment the session last moved from paused -> tracking
  // (or started, if never paused) — mirrors WorkoutSessionState.resumedAt
  // exactly, same reasoning: elapsed-since-resume plus the already-
  // accumulated activeDurationSeconds gives the true active duration
  // without a running timer needing to persist ticks.
  final DateTime resumedAt;
  final DateTime? pausedAt;
  final int activeDurationSeconds;
  final double distanceMeters;
  final List<RoutePoint> routePoints;
  // The most recent accepted GPS fix's own timestamp — used to compute a
  // simple current-pace estimate from the last two points, separately
  // from resumedAt (which tracks pause/resume, not GPS fix cadence).
  final DateTime? lastFixAt;
  // True when this session is paused because Ascend stopped tracking on
  // its own — the app was backgrounded (see LiveCardioScreen's
  // WidgetsBindingObserver) or the process was killed and this session
  // was recovered from cache on relaunch — rather than the user tapping
  // Pause themselves. Location is never tracked in the background (see
  // GeolocatorLiveLocationService's doc comment); this flag exists so
  // the UI can say so honestly instead of leaving the user to wonder why
  // their run stopped recording.
  final bool pausedForBackground;

  bool get isTracking => status == LiveCardioStatus.tracking;

  /// Active duration including time elapsed since the last resume — the
  /// number to actually display while tracking is live.
  int liveActiveDurationSeconds({DateTime? now}) {
    if (status != LiveCardioStatus.tracking) return activeDurationSeconds;
    final elapsed = (now ?? DateTime.now()).difference(resumedAt).inSeconds;
    return activeDurationSeconds + (elapsed < 0 ? 0 : elapsed);
  }

  double? get averagePaceSecondsPerKm {
    if (distanceMeters <= 0) return null;
    final duration = liveActiveDurationSeconds();
    if (duration <= 0) return null;
    return duration / (distanceMeters / 1000);
  }

  LiveCardioSessionState copyWith({
    LiveCardioStatus? status,
    DateTime? resumedAt,
    DateTime? pausedAt,
    bool clearPausedAt = false,
    int? activeDurationSeconds,
    double? distanceMeters,
    List<RoutePoint>? routePoints,
    DateTime? lastFixAt,
    bool? pausedForBackground,
  }) {
    return LiveCardioSessionState(
      localId: localId,
      userId: userId,
      activityType: activityType,
      status: status ?? this.status,
      startedAt: startedAt,
      resumedAt: resumedAt ?? this.resumedAt,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
      activeDurationSeconds:
          activeDurationSeconds ?? this.activeDurationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      routePoints: routePoints ?? this.routePoints,
      lastFixAt: lastFixAt ?? this.lastFixAt,
      pausedForBackground: pausedForBackground ?? this.pausedForBackground,
    );
  }

  Map<String, dynamic> toCacheJson() => {
    'localId': localId,
    'userId': userId,
    'activityType': cardioActivityTypeToJson(activityType),
    'status': status.name,
    'startedAt': startedAt.toIso8601String(),
    'resumedAt': resumedAt.toIso8601String(),
    'pausedAt': pausedAt?.toIso8601String(),
    'activeDurationSeconds': activeDurationSeconds,
    'distanceMeters': distanceMeters,
    'routePoints': routePoints.map((p) => p.toJson()).toList(),
    'lastFixAt': lastFixAt?.toIso8601String(),
    'pausedForBackground': pausedForBackground,
  };

  factory LiveCardioSessionState.fromCacheJson(Map<String, dynamic> json) {
    return LiveCardioSessionState(
      localId: json['localId'] as String,
      userId: json['userId'] as String,
      activityType: cardioActivityTypeFromJson(json['activityType'] as String),
      status: LiveCardioStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => LiveCardioStatus.paused,
      ),
      startedAt: DateTime.parse(json['startedAt'] as String),
      resumedAt: DateTime.parse(json['resumedAt'] as String),
      pausedAt: json['pausedAt'] != null
          ? DateTime.parse(json['pausedAt'] as String)
          : null,
      activeDurationSeconds: json['activeDurationSeconds'] as int,
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      routePoints: (json['routePoints'] as List<dynamic>)
          .map((p) => RoutePoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      lastFixAt: json['lastFixAt'] != null
          ? DateTime.parse(json['lastFixAt'] as String)
          : null,
      pausedForBackground: json['pausedForBackground'] as bool? ?? false,
    );
  }
}
