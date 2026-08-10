import 'package:mobile/features/joint_workouts/data/joint_workout_sessions_repository.dart';
import 'package:mobile/features/joint_workouts/domain/joint_workout_session.dart';

JointWorkoutParticipant sampleParticipant({
  String id = 'participant-1',
  String userId = 'user-1',
  JointWorkoutParticipantStatus status = JointWorkoutParticipantStatus.accepted,
  List<JointWorkoutSharedResult> results = const [],
}) {
  return JointWorkoutParticipant(
    id: id,
    userId: userId,
    status: status,
    results: results,
  );
}

JointWorkoutSession sampleJointWorkoutSession({
  String id = 'session-1',
  String hostId = 'user-1',
  String? title = 'Leg day',
  JointWorkoutSessionStatus status = JointWorkoutSessionStatus.created,
  List<JointWorkoutParticipant> participants = const [],
}) {
  return JointWorkoutSession(
    id: id,
    hostId: hostId,
    title: title,
    status: status,
    createdAt: DateTime.utc(2026, 8, 7),
    participants: participants,
  );
}

/// In-memory stand-in for [JointWorkoutSessionsRepository]. `'user-1'` is
/// the signed-in test user's id (see FakeAuthRepository).
class FakeJointWorkoutSessionsRepository
    implements JointWorkoutSessionsRepository {
  FakeJointWorkoutSessionsRepository({List<JointWorkoutSession>? sessions})
    : sessions = sessions ?? [];

  final List<JointWorkoutSession> sessions;
  String? lastInvitedUserId;
  String? lastProgressExerciseName;
  String? lastTrainerGroupId;
  String? lastStartedScheduledSessionId;
  String? lastJoinedScheduledSessionId;

  /// Overrides the session [startFromScheduledSession]/
  /// [joinFromScheduledSession] return — tests assert on
  /// [lastStartedScheduledSessionId]/[lastJoinedScheduledSessionId] for
  /// which booking triggered the call, and can set this to control the
  /// returned live session's id (e.g. to verify navigation).
  JointWorkoutSession? scheduledSessionActionResult;

  /// Test fixture standing in for the real backend's
  /// TrainerGroupsService.resolveGroupSessionInvitees — seed a group's
  /// resolved member ids here before calling [create] with a
  /// `trainerGroupId`.
  final Map<String, List<String>> groupMemberIdsByGroupId = {};

  @override
  Future<List<JointWorkoutSession>> listMine() async =>
      List.unmodifiable(sessions);

  @override
  Future<JointWorkoutSession> create({
    String? title,
    List<String>? inviteeIds,
    String? trainerGroupId,
  }) async {
    lastTrainerGroupId = trainerGroupId;
    final resolvedInviteeIds = trainerGroupId != null
        ? (groupMemberIdsByGroupId[trainerGroupId] ?? const <String>[])
        : (inviteeIds ?? const <String>[]);
    final session = JointWorkoutSession(
      id: 'session-${sessions.length + 1}',
      hostId: 'user-1',
      title: title,
      status: JointWorkoutSessionStatus.created,
      createdAt: DateTime.utc(2026, 8, 7),
      participants: [
        sampleParticipant(id: 'p-host', userId: 'user-1'),
        for (final inviteeId in resolvedInviteeIds)
          sampleParticipant(
            id: 'p-$inviteeId',
            userId: inviteeId,
            status: JointWorkoutParticipantStatus.invited,
          ),
      ],
    );
    sessions.add(session);
    return session;
  }

  @override
  Future<JointWorkoutSession> getById(String sessionId) async {
    return sessions.firstWhere((s) => s.id == sessionId);
  }

  @override
  Future<JointWorkoutSession> startFromScheduledSession(
    String scheduledSessionId,
  ) async {
    lastStartedScheduledSessionId = scheduledSessionId;
    final session =
        scheduledSessionActionResult ??
        sampleJointWorkoutSession(id: 'joint-from-$scheduledSessionId');
    if (!sessions.any((s) => s.id == session.id)) sessions.add(session);
    return session;
  }

  @override
  Future<JointWorkoutSession> joinFromScheduledSession(
    String scheduledSessionId,
  ) async {
    lastJoinedScheduledSessionId = scheduledSessionId;
    return scheduledSessionActionResult ??
        sampleJointWorkoutSession(id: 'joint-from-$scheduledSessionId');
  }

  @override
  Future<void> invite(String sessionId, String inviteeId) async {
    lastInvitedUserId = inviteeId;
    _replaceParticipants(
      sessionId,
      (participants) => [
        ...participants,
        sampleParticipant(
          id: 'p-$inviteeId',
          userId: inviteeId,
          status: JointWorkoutParticipantStatus.invited,
        ),
      ],
    );
  }

  @override
  Future<void> accept(String sessionId) =>
      _updateMyStatus(sessionId, JointWorkoutParticipantStatus.accepted);

  @override
  Future<void> decline(String sessionId) =>
      _updateMyStatus(sessionId, JointWorkoutParticipantStatus.declined);

  @override
  Future<void> ready(String sessionId) =>
      _updateMyStatus(sessionId, JointWorkoutParticipantStatus.ready);

  @override
  Future<void> start(String sessionId) async {
    final index = sessions.indexWhere((s) => s.id == sessionId);
    final session = sessions[index];
    sessions[index] = JointWorkoutSession(
      id: session.id,
      hostId: session.hostId,
      title: session.title,
      status: JointWorkoutSessionStatus.inProgress,
      createdAt: session.createdAt,
      participants: [
        for (final p in session.participants)
          if (p.status == JointWorkoutParticipantStatus.ready)
            sampleParticipant(
              id: p.id,
              userId: p.userId,
              status: JointWorkoutParticipantStatus.active,
              results: p.results,
            )
          else
            p,
      ],
    );
  }

  @override
  Future<void> submitProgress(
    String sessionId, {
    String? exerciseName,
    int? setsCompleted,
    int? durationSeconds,
    double? distanceMeters,
    bool? isPersonalRecord,
  }) async {
    lastProgressExerciseName = exerciseName;
    _replaceParticipants(sessionId, (participants) {
      return [
        for (final p in participants)
          if (p.userId == 'user-1')
            sampleParticipant(
              id: p.id,
              userId: p.userId,
              status: p.status,
              results: [
                ...p.results,
                JointWorkoutSharedResult(
                  id: 'result-${p.results.length + 1}',
                  exerciseName: exerciseName,
                  setsCompleted: setsCompleted,
                  durationSeconds: durationSeconds,
                  distanceMeters: distanceMeters,
                  isPersonalRecord: isPersonalRecord ?? false,
                  createdAt: DateTime.utc(2026, 8, 7),
                ),
              ],
            )
          else
            p,
      ];
    });
  }

  @override
  Future<void> finish(String sessionId) =>
      _updateMyStatus(sessionId, JointWorkoutParticipantStatus.finished);

  @override
  Future<void> leave(String sessionId) =>
      _updateMyStatus(sessionId, JointWorkoutParticipantStatus.left);

  @override
  Future<void> cancel(String sessionId) async {
    final index = sessions.indexWhere((s) => s.id == sessionId);
    final session = sessions[index];
    sessions[index] = JointWorkoutSession(
      id: session.id,
      hostId: session.hostId,
      title: session.title,
      status: JointWorkoutSessionStatus.canceled,
      createdAt: session.createdAt,
      participants: session.participants,
    );
  }

  Future<void> _updateMyStatus(
    String sessionId,
    JointWorkoutParticipantStatus status,
  ) async {
    _replaceParticipants(sessionId, (participants) {
      return [
        for (final p in participants)
          if (p.userId == 'user-1')
            sampleParticipant(
              id: p.id,
              userId: p.userId,
              status: status,
              results: p.results,
            )
          else
            p,
      ];
    });
  }

  void _replaceParticipants(
    String sessionId,
    List<JointWorkoutParticipant> Function(List<JointWorkoutParticipant>)
    update,
  ) {
    final index = sessions.indexWhere((s) => s.id == sessionId);
    final session = sessions[index];
    sessions[index] = JointWorkoutSession(
      id: session.id,
      hostId: session.hostId,
      title: session.title,
      status: session.status,
      createdAt: session.createdAt,
      participants: update(session.participants),
    );
  }
}
