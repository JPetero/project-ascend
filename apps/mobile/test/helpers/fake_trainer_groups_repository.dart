import 'package:mobile/features/trainer_groups/data/trainer_groups_repository.dart';
import 'package:mobile/features/trainer_groups/domain/trainer_group.dart';

TrainerGroup sampleGroup({
  String id = 'group-1',
  String ownerId = 'owner-1',
  String name = 'Morning Crew',
  int memberLimit = 5,
  bool isExpanded = false,
  bool isOwnGroup = false,
  List<TrainerGroupMember>? members,
}) {
  return TrainerGroup(
    id: id,
    ownerId: ownerId,
    name: name,
    memberLimit: memberLimit,
    isExpanded: isExpanded,
    isOwnGroup: isOwnGroup,
    createdAt: DateTime.utc(2026, 8, 6),
    members:
        members ??
        [
          TrainerGroupMember(
            userId: ownerId,
            role: TrainerGroupMemberRole.owner,
            joinedAt: DateTime.utc(2026, 8, 6),
            displayName: 'Ada',
          ),
        ],
  );
}

/// In-memory stand-in for [TrainerGroupsRepository].
class FakeTrainerGroupsRepository implements TrainerGroupsRepository {
  FakeTrainerGroupsRepository({
    List<TrainerGroup>? groups,
    List<TrainerGroupInvitation>? invitations,
  }) : groups = groups ?? [],
       invitations = invitations ?? [];

  final List<TrainerGroup> groups;
  final List<TrainerGroupInvitation> invitations;
  final Map<String, List<TrainerGroupMessage>> messagesByGroup = {};
  final Map<String, List<TrainerGroupSharedPlan>> sharedPlansByGroup = {};
  final Map<String, List<TrainerGroupAnnouncement>> announcementsByGroup = {};
  final List<({String groupId, String inviteeUserId})> invitesSent = [];
  final List<({String groupId, String userId, TrainerGroupMemberRole role})>
  roleChanges = [];
  bool failSetMemberRole = false;
  bool failPostAnnouncement = false;
  final List<WorkoutAssignment> assignments = [];
  final List<TrainerGroupScheduledSession> scheduledSessions = [];
  TrainerDashboard dashboard = const TrainerDashboard(
    groups: [],
    upcomingSessions: [],
    recentAssignments: [],
  );

  @override
  Future<TrainerGroup> createGroup({
    required String name,
    String? description,
  }) async {
    final group = sampleGroup(
      id: 'group-${groups.length}',
      name: name,
      isOwnGroup: true,
    );
    groups.add(group);
    return group;
  }

  @override
  Future<List<TrainerGroup>> listMyGroups() async => List.unmodifiable(groups);

  @override
  Future<TrainerGroup> getGroup(String id) async {
    return groups.firstWhere(
      (g) => g.id == id,
      orElse: () => throw Exception('not found'),
    );
  }

  @override
  Future<void> deleteGroup(String id) async {
    groups.removeWhere((g) => g.id == id);
  }

  @override
  Future<List<TrainerGroupInvitation>> listMyInvitations() async =>
      List.unmodifiable(invitations);

  @override
  Future<void> invite(String groupId, String inviteeUserId) async {
    invitesSent.add((groupId: groupId, inviteeUserId: inviteeUserId));
  }

  @override
  Future<void> acceptInvitation(String invitationId) async {
    invitations.removeWhere((i) => i.id == invitationId);
  }

  @override
  Future<void> declineInvitation(String invitationId) async {
    invitations.removeWhere((i) => i.id == invitationId);
  }

  @override
  Future<void> cancelInvitation(String invitationId) async {
    invitations.removeWhere((i) => i.id == invitationId);
  }

  @override
  Future<void> removeMember(String groupId, String userId) async {
    final index = groups.indexWhere((g) => g.id == groupId);
    if (index == -1) return;
    final group = groups[index];
    groups[index] = TrainerGroup(
      id: group.id,
      ownerId: group.ownerId,
      name: group.name,
      description: group.description,
      memberLimit: group.memberLimit,
      isExpanded: group.isExpanded,
      isOwnGroup: group.isOwnGroup,
      createdAt: group.createdAt,
      members: group.members.where((m) => m.userId != userId).toList(),
    );
  }

  @override
  Future<TrainerGroupMemberRole> setMemberRole(
    String groupId,
    String userId,
    TrainerGroupMemberRole role,
  ) async {
    if (failSetMemberRole) throw Exception('failed to set role');
    roleChanges.add((groupId: groupId, userId: userId, role: role));
    final index = groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final group = groups[index];
      groups[index] = TrainerGroup(
        id: group.id,
        ownerId: group.ownerId,
        name: group.name,
        description: group.description,
        memberLimit: group.memberLimit,
        isExpanded: group.isExpanded,
        isOwnGroup: group.isOwnGroup,
        createdAt: group.createdAt,
        members: [
          for (final member in group.members)
            if (member.userId == userId)
              TrainerGroupMember(
                userId: member.userId,
                role: role,
                joinedAt: member.joinedAt,
                displayName: member.displayName,
                avatarUrl: member.avatarUrl,
              )
            else
              member,
        ],
      );
    }
    return role;
  }

  @override
  Future<TrainerGroupAnnouncement> postAnnouncement(
    String groupId,
    String body,
  ) async {
    if (failPostAnnouncement) throw Exception('failed to post');
    final announcement = TrainerGroupAnnouncement(
      id: 'announcement-${(announcementsByGroup[groupId]?.length ?? 0)}',
      groupId: groupId,
      authorId: 'me',
      body: body,
      createdAt: DateTime.now(),
    );
    announcementsByGroup.putIfAbsent(groupId, () => []).insert(0, announcement);
    return announcement;
  }

  @override
  Future<List<TrainerGroupAnnouncement>> listAnnouncements(
    String groupId,
  ) async {
    return List.unmodifiable(announcementsByGroup[groupId] ?? []);
  }

  @override
  Future<TrainerGroupMessage> sendMessage(
    String groupId, {
    String? body,
    String? imageUrl,
  }) async {
    final message = TrainerGroupMessage(
      id: 'message-${(messagesByGroup[groupId]?.length ?? 0)}',
      groupId: groupId,
      authorId: 'me',
      body: body,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );
    messagesByGroup.putIfAbsent(groupId, () => []).add(message);
    return message;
  }

  @override
  Future<List<TrainerGroupMessage>> listMessages(
    String groupId, {
    int page = 1,
    int limit = 50,
  }) async {
    return List.unmodifiable((messagesByGroup[groupId] ?? []).reversed);
  }

  @override
  Future<TrainerGroupSharedPlan> sharePlan(
    String groupId,
    String workoutPlanId,
  ) async {
    final shared = TrainerGroupSharedPlan(
      id: 'shared-${(sharedPlansByGroup[groupId]?.length ?? 0)}',
      sharedById: 'me',
      createdAt: DateTime.now(),
      workoutPlanId: workoutPlanId,
      workoutPlanName: 'Plan $workoutPlanId',
    );
    sharedPlansByGroup.putIfAbsent(groupId, () => []).add(shared);
    return shared;
  }

  @override
  Future<List<TrainerGroupSharedPlan>> listSharedPlans(String groupId) async {
    return List.unmodifiable(sharedPlansByGroup[groupId] ?? []);
  }

  @override
  Future<void> unsharePlan(String groupId, String sharedPlanId) async {
    sharedPlansByGroup[groupId]?.removeWhere((p) => p.id == sharedPlanId);
  }

  @override
  Future<List<WorkoutAssignment>> createAssignments(
    String groupId, {
    required String workoutPlanId,
    required List<String> assigneeUserIds,
    String? note,
    DateTime? dueAt,
  }) async {
    final created = [
      for (final assigneeId in assigneeUserIds)
        WorkoutAssignment(
          id: 'assignment-${assignments.length}',
          groupId: groupId,
          assignedById: 'me',
          assigneeId: assigneeId,
          sourcePlanId: workoutPlanId,
          sourcePlanName: 'Plan $workoutPlanId',
          note: note,
          dueAt: dueAt,
          status: WorkoutAssignmentStatus.pending,
          createdAt: DateTime.now(),
        ),
    ];
    assignments.addAll(created);
    return created;
  }

  @override
  Future<WorkoutAssignment> declineAssignment(String assignmentId) async {
    final index = assignments.indexWhere((a) => a.id == assignmentId);
    final existing = assignments[index];
    final updated = WorkoutAssignment(
      id: existing.id,
      groupId: existing.groupId,
      assignedById: existing.assignedById,
      assigneeId: existing.assigneeId,
      sourcePlanId: existing.sourcePlanId,
      sourcePlanName: existing.sourcePlanName,
      assignedPlanId: existing.assignedPlanId,
      note: existing.note,
      dueAt: existing.dueAt,
      status: WorkoutAssignmentStatus.declined,
      createdAt: existing.createdAt,
      completedAt: existing.completedAt,
    );
    assignments[index] = updated;
    return updated;
  }

  @override
  Future<List<WorkoutAssignment>> listGroupAssignments(String groupId) async {
    return List.unmodifiable(assignments.where((a) => a.groupId == groupId));
  }

  @override
  Future<List<WorkoutAssignment>> listMyAssignments() async =>
      List.unmodifiable(assignments);

  @override
  Future<String> acceptAssignment(String assignmentId) async {
    final index = assignments.indexWhere((a) => a.id == assignmentId);
    final existing = assignments[index];
    final clonedPlanId = 'cloned-${existing.sourcePlanId}';
    assignments[index] = WorkoutAssignment(
      id: existing.id,
      groupId: existing.groupId,
      assignedById: existing.assignedById,
      assigneeId: existing.assigneeId,
      sourcePlanId: existing.sourcePlanId,
      sourcePlanName: existing.sourcePlanName,
      assignedPlanId: clonedPlanId,
      note: existing.note,
      dueAt: existing.dueAt,
      status: WorkoutAssignmentStatus.accepted,
      createdAt: existing.createdAt,
    );
    return clonedPlanId;
  }

  @override
  Future<void> cancelAssignment(String assignmentId) async {
    assignments.removeWhere((a) => a.id == assignmentId);
  }

  @override
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
    final session = TrainerGroupScheduledSession(
      id: 'session-${scheduledSessions.length}',
      groupId: groupId,
      createdById: 'me',
      title: title,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      location: location,
      videoLink: videoLink,
      description: description,
      workoutPlanId: workoutPlanId,
      createdAt: DateTime.now(),
    );
    scheduledSessions.add(session);
    return session;
  }

  @override
  Future<List<TrainerGroupScheduledSession>> listScheduledSessions(
    String groupId,
  ) async {
    return List.unmodifiable(
      scheduledSessions.where(
        (s) => s.groupId == groupId && s.canceledAt == null,
      ),
    );
  }

  @override
  Future<void> cancelScheduledSession(String sessionId) async {
    scheduledSessions.removeWhere((s) => s.id == sessionId);
  }

  @override
  Future<TrainerGroupScheduledSession> rsvpToScheduledSession(
    String sessionId,
    ScheduledSessionRsvpStatus status,
  ) async {
    final index = scheduledSessions.indexWhere((s) => s.id == sessionId);
    final current = scheduledSessions[index];
    final updated = TrainerGroupScheduledSession(
      id: current.id,
      groupId: current.groupId,
      createdById: current.createdById,
      title: current.title,
      scheduledAt: current.scheduledAt,
      durationMinutes: current.durationMinutes,
      location: current.location,
      videoLink: current.videoLink,
      description: current.description,
      workoutPlanId: current.workoutPlanId,
      workoutPlanName: current.workoutPlanName,
      canceledAt: current.canceledAt,
      createdAt: current.createdAt,
      status: current.status,
      goingCount: status == ScheduledSessionRsvpStatus.going ? 1 : 0,
      maybeCount: status == ScheduledSessionRsvpStatus.maybe ? 1 : 0,
      declinedCount: status == ScheduledSessionRsvpStatus.declined ? 1 : 0,
      viewerRsvpStatus: status,
    );
    scheduledSessions[index] = updated;
    return updated;
  }

  @override
  Future<TrainerGroupScheduledSession> cancelMyRsvp(String sessionId) async {
    final index = scheduledSessions.indexWhere((s) => s.id == sessionId);
    final current = scheduledSessions[index];
    final updated = TrainerGroupScheduledSession(
      id: current.id,
      groupId: current.groupId,
      createdById: current.createdById,
      title: current.title,
      scheduledAt: current.scheduledAt,
      durationMinutes: current.durationMinutes,
      location: current.location,
      videoLink: current.videoLink,
      description: current.description,
      workoutPlanId: current.workoutPlanId,
      workoutPlanName: current.workoutPlanName,
      canceledAt: current.canceledAt,
      createdAt: current.createdAt,
      status: current.status,
    );
    scheduledSessions[index] = updated;
    return updated;
  }

  @override
  Future<TrainerDashboard> getTrainerDashboard() async => dashboard;
}
