import '../../../core/networking/api_client.dart';
import '../domain/trainer_group.dart';

/// Thin client for services/api/src/modules/trainer-groups — free-tier
/// group creation, invitations, membership, text/image chat, and shared
/// workout plans. See packages/docs/product/user-scenario-bible.md
/// Scenario 24.
class TrainerGroupsRepository {
  TrainerGroupsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<TrainerGroup> createGroup({
    required String name,
    String? description,
  }) async {
    final envelope = await _apiClient.post(
      '/trainer-groups',
      (data) => data as Map<String, dynamic>,
      data: {'name': name, 'description': ?description},
    );
    return TrainerGroup.fromJson(envelope.data!);
  }

  Future<List<TrainerGroup>> listMyGroups() async {
    final envelope = await _apiClient.get(
      '/trainer-groups',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map((g) => TrainerGroup.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  Future<TrainerGroup> getGroup(String id) async {
    final envelope = await _apiClient.get(
      '/trainer-groups/$id',
      (data) => data as Map<String, dynamic>,
    );
    return TrainerGroup.fromJson(envelope.data!);
  }

  Future<void> deleteGroup(String id) async {
    await _apiClient.delete('/trainer-groups/$id', (_) => null);
  }

  Future<List<TrainerGroupInvitation>> listMyInvitations() async {
    final envelope = await _apiClient.get(
      '/trainer-groups/invitations',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map((i) => TrainerGroupInvitation.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<void> invite(String groupId, String inviteeUserId) async {
    await _apiClient.post(
      '/trainer-groups/$groupId/invitations',
      (_) => null,
      data: {'inviteeUserId': inviteeUserId},
    );
  }

  Future<void> acceptInvitation(String invitationId) async {
    await _apiClient.post(
      '/trainer-groups/invitations/$invitationId/accept',
      (_) => null,
    );
  }

  Future<void> declineInvitation(String invitationId) async {
    await _apiClient.post(
      '/trainer-groups/invitations/$invitationId/decline',
      (_) => null,
    );
  }

  Future<void> cancelInvitation(String invitationId) async {
    await _apiClient.delete(
      '/trainer-groups/invitations/$invitationId',
      (_) => null,
    );
  }

  Future<void> removeMember(String groupId, String userId) async {
    await _apiClient.delete(
      '/trainer-groups/$groupId/members/$userId',
      (_) => null,
    );
  }

  Future<TrainerGroupMessage> sendMessage(
    String groupId, {
    String? body,
    String? imageUrl,
  }) async {
    final envelope = await _apiClient.post(
      '/trainer-groups/$groupId/messages',
      (data) => data as Map<String, dynamic>,
      data: {'body': ?body, 'imageUrl': ?imageUrl},
    );
    return TrainerGroupMessage.fromJson(envelope.data!);
  }

  Future<List<TrainerGroupMessage>> listMessages(
    String groupId, {
    int page = 1,
    int limit = 50,
  }) async {
    final envelope = await _apiClient.get(
      '/trainer-groups/$groupId/messages',
      (data) => data as Map<String, dynamic>,
      query: {'page': page, 'limit': limit},
    );
    final items = envelope.data!['data'] as List<dynamic>;
    return items
        .map((m) => TrainerGroupMessage.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<TrainerGroupSharedPlan> sharePlan(
    String groupId,
    String workoutPlanId,
  ) async {
    final envelope = await _apiClient.post(
      '/trainer-groups/$groupId/shared-plans',
      (data) => data as Map<String, dynamic>,
      data: {'workoutPlanId': workoutPlanId},
    );
    return TrainerGroupSharedPlan.fromJson(envelope.data!);
  }

  Future<List<TrainerGroupSharedPlan>> listSharedPlans(String groupId) async {
    final envelope = await _apiClient.get(
      '/trainer-groups/$groupId/shared-plans',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map((s) => TrainerGroupSharedPlan.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<void> unsharePlan(String groupId, String sharedPlanId) async {
    await _apiClient.delete(
      '/trainer-groups/$groupId/shared-plans/$sharedPlanId',
      (_) => null,
    );
  }

  Future<TrainerGroupMemberRole> setMemberRole(
    String groupId,
    String userId,
    TrainerGroupMemberRole role,
  ) async {
    final envelope = await _apiClient.patch(
      '/trainer-groups/$groupId/members/$userId/role',
      (data) => data as Map<String, dynamic>,
      data: {'role': trainerGroupMemberRoleToJson(role)},
    );
    return trainerGroupMemberRoleFromJson(envelope.data!['role'] as String);
  }

  Future<TrainerGroupAnnouncement> postAnnouncement(
    String groupId,
    String body,
  ) async {
    final envelope = await _apiClient.post(
      '/trainer-groups/$groupId/announcements',
      (data) => data as Map<String, dynamic>,
      data: {'body': body},
    );
    return TrainerGroupAnnouncement.fromJson(envelope.data!);
  }

  Future<List<TrainerGroupAnnouncement>> listAnnouncements(
    String groupId,
  ) async {
    final envelope = await _apiClient.get(
      '/trainer-groups/$groupId/announcements',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map(
          (a) => TrainerGroupAnnouncement.fromJson(a as Map<String, dynamic>),
        )
        .toList();
  }

  // --- Workout assignments (Build Session 12 Part 9) ----------------------

  Future<List<WorkoutAssignment>> createAssignments(
    String groupId, {
    required String workoutPlanId,
    required List<String> assigneeUserIds,
    String? note,
  }) async {
    final envelope = await _apiClient.post(
      '/trainer-groups/$groupId/assignments',
      (data) => data as List<dynamic>,
      data: {
        'workoutPlanId': workoutPlanId,
        'assigneeUserIds': assigneeUserIds,
        'note': ?note,
      },
    );
    return envelope.data!
        .map((a) => WorkoutAssignment.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<List<WorkoutAssignment>> listGroupAssignments(String groupId) async {
    final envelope = await _apiClient.get(
      '/trainer-groups/$groupId/assignments',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map((a) => WorkoutAssignment.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<List<WorkoutAssignment>> listMyAssignments() async {
    final envelope = await _apiClient.get(
      '/trainer-groups/assignments/mine',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map((a) => WorkoutAssignment.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  /// Returns the id of the new workout plan cloned into the caller's own
  /// plans — the caller starts a session against it exactly like any
  /// other plan of theirs.
  Future<String> acceptAssignment(String assignmentId) async {
    final envelope = await _apiClient.post(
      '/trainer-groups/assignments/$assignmentId/accept',
      (data) => data as Map<String, dynamic>,
    );
    return envelope.data!['workoutPlanId'] as String;
  }

  Future<void> cancelAssignment(String assignmentId) async {
    await _apiClient.delete(
      '/trainer-groups/assignments/$assignmentId',
      (_) => null,
    );
  }

  // --- Scheduled sessions (Build Session 12 Part 10) -----------------------

  Future<TrainerGroupScheduledSession> createScheduledSession(
    String groupId, {
    required DateTime scheduledAt,
    String? title,
    int? durationMinutes,
    String? location,
    String? videoLink,
    String? description,
    String? workoutPlanId,
  }) async {
    final envelope = await _apiClient.post(
      '/trainer-groups/$groupId/scheduled-sessions',
      (data) => data as Map<String, dynamic>,
      data: {
        'scheduledAt': scheduledAt.toIso8601String(),
        'title': ?title,
        'durationMinutes': ?durationMinutes,
        'location': ?location,
        'videoLink': ?videoLink,
        'description': ?description,
        'workoutPlanId': ?workoutPlanId,
      },
    );
    return TrainerGroupScheduledSession.fromJson(envelope.data!);
  }

  Future<List<TrainerGroupScheduledSession>> listScheduledSessions(
    String groupId,
  ) async {
    final envelope = await _apiClient.get(
      '/trainer-groups/$groupId/scheduled-sessions',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map(
          (s) =>
              TrainerGroupScheduledSession.fromJson(s as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> cancelScheduledSession(String sessionId) async {
    await _apiClient.delete(
      '/trainer-groups/scheduled-sessions/$sessionId',
      (_) => null,
    );
  }

  /// RSVP Going/Maybe/Decline (Build Session 13 Part 3). Returns the full
  /// session with updated counts, so the caller can replace its local copy
  /// directly instead of re-fetching the whole list.
  Future<TrainerGroupScheduledSession> rsvpToScheduledSession(
    String sessionId,
    ScheduledSessionRsvpStatus status,
  ) async {
    final envelope = await _apiClient.post(
      '/trainer-groups/scheduled-sessions/$sessionId/rsvp',
      (data) => data as Map<String, dynamic>,
      data: {'status': status.wireValue},
    );
    return TrainerGroupScheduledSession.fromJson(envelope.data!);
  }

  /// Returns to the "hasn't responded" state — idempotent even if the
  /// caller never RSVP'd.
  Future<TrainerGroupScheduledSession> cancelMyRsvp(String sessionId) async {
    final envelope = await _apiClient.delete(
      '/trainer-groups/scheduled-sessions/$sessionId/rsvp',
      (data) => data as Map<String, dynamic>,
    );
    return TrainerGroupScheduledSession.fromJson(envelope.data!);
  }

  // --- Trainer dashboard (Build Session 12 Part 11) -------------------------

  Future<TrainerDashboard> getTrainerDashboard() async {
    final envelope = await _apiClient.get(
      '/trainer-groups/dashboard',
      (data) => data as Map<String, dynamic>,
    );
    return TrainerDashboard.fromJson(envelope.data!);
  }
}
