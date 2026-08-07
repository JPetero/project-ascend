enum JointWorkoutSessionStatus { created, inProgress, finished, canceled }

JointWorkoutSessionStatus jointWorkoutSessionStatusFromJson(String value) {
  switch (value) {
    case 'IN_PROGRESS':
      return JointWorkoutSessionStatus.inProgress;
    case 'FINISHED':
      return JointWorkoutSessionStatus.finished;
    case 'CANCELED':
      return JointWorkoutSessionStatus.canceled;
    default:
      return JointWorkoutSessionStatus.created;
  }
}

enum JointWorkoutParticipantStatus {
  invited,
  accepted,
  declined,
  ready,
  active,
  finished,
  left,
}

JointWorkoutParticipantStatus jointWorkoutParticipantStatusFromJson(
  String value,
) {
  switch (value) {
    case 'ACCEPTED':
      return JointWorkoutParticipantStatus.accepted;
    case 'DECLINED':
      return JointWorkoutParticipantStatus.declined;
    case 'READY':
      return JointWorkoutParticipantStatus.ready;
    case 'ACTIVE':
      return JointWorkoutParticipantStatus.active;
    case 'FINISHED':
      return JointWorkoutParticipantStatus.finished;
    case 'LEFT':
      return JointWorkoutParticipantStatus.left;
    default:
      return JointWorkoutParticipantStatus.invited;
  }
}

/// Sets/duration/exercises/PRs/distance only — see the backend schema's
/// doc comment on JointWorkoutSharedResult. Never carries weight, BMI, a
/// health condition, nutrition data, heart rate, or a wearable metric.
class JointWorkoutSharedResult {
  const JointWorkoutSharedResult({
    required this.id,
    this.exerciseName,
    this.setsCompleted,
    this.durationSeconds,
    this.distanceMeters,
    required this.isPersonalRecord,
    required this.createdAt,
  });

  final String id;
  final String? exerciseName;
  final int? setsCompleted;
  final int? durationSeconds;
  final double? distanceMeters;
  final bool isPersonalRecord;
  final DateTime createdAt;

  factory JointWorkoutSharedResult.fromJson(Map<String, dynamic> json) {
    return JointWorkoutSharedResult(
      id: json['id'] as String,
      exerciseName: json['exerciseName'] as String?,
      setsCompleted: json['setsCompleted'] as int?,
      durationSeconds: json['durationSeconds'] as int?,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      isPersonalRecord: json['isPersonalRecord'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class JointWorkoutParticipant {
  const JointWorkoutParticipant({
    required this.id,
    required this.userId,
    required this.status,
    this.results = const [],
  });

  final String id;
  final String userId;
  final JointWorkoutParticipantStatus status;
  final List<JointWorkoutSharedResult> results;

  factory JointWorkoutParticipant.fromJson(Map<String, dynamic> json) {
    final resultsJson = json['results'] as List<dynamic>?;
    return JointWorkoutParticipant(
      id: json['id'] as String,
      userId: json['userId'] as String,
      status: jointWorkoutParticipantStatusFromJson(json['status'] as String),
      results:
          resultsJson
              ?.map(
                (r) => JointWorkoutSharedResult.fromJson(
                  r as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
    );
  }
}

class JointWorkoutEvent {
  const JointWorkoutEvent({
    required this.id,
    this.userId,
    required this.type,
    this.message,
    required this.createdAt,
  });

  final String id;
  final String? userId;
  final String type;
  final String? message;
  final DateTime createdAt;

  factory JointWorkoutEvent.fromJson(Map<String, dynamic> json) {
    return JointWorkoutEvent(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      type: json['type'] as String,
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// A friend-only joint workout session — Build Session 8 Part 9. See
/// services/api/prisma/schema.prisma's Joint Workout Sessions comment:
/// every participant must already be a Friend of the host, and no
/// health metric (weight, BMI, heart rate, nutrition, wearable data) is
/// ever shared through this feature.
class JointWorkoutSession {
  const JointWorkoutSession({
    required this.id,
    required this.hostId,
    this.title,
    required this.status,
    required this.createdAt,
    this.participants = const [],
    this.events = const [],
  });

  final String id;
  final String hostId;
  final String? title;
  final JointWorkoutSessionStatus status;
  final DateTime createdAt;
  final List<JointWorkoutParticipant> participants;
  final List<JointWorkoutEvent> events;

  factory JointWorkoutSession.fromJson(Map<String, dynamic> json) {
    final participantsJson = json['participants'] as List<dynamic>?;
    final eventsJson = json['events'] as List<dynamic>?;
    return JointWorkoutSession(
      id: json['id'] as String,
      hostId: json['hostId'] as String,
      title: json['title'] as String?,
      status: jointWorkoutSessionStatusFromJson(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      participants:
          participantsJson
              ?.map(
                (p) =>
                    JointWorkoutParticipant.fromJson(p as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      events:
          eventsJson
              ?.map(
                (e) => JointWorkoutEvent.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }
}
