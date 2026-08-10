enum TrainerGroupMemberRole { owner, moderator, member }

TrainerGroupMemberRole trainerGroupMemberRoleFromJson(String value) =>
    TrainerGroupMemberRole.values.firstWhere(
      (r) => r.name.toUpperCase() == value,
      orElse: () => TrainerGroupMemberRole.member,
    );

String trainerGroupMemberRoleToJson(TrainerGroupMemberRole role) =>
    role.name.toUpperCase();

enum TrainerGroupInvitationStatus { pending, accepted, declined, canceled }

TrainerGroupInvitationStatus trainerGroupInvitationStatusFromJson(
  String value,
) => TrainerGroupInvitationStatus.values.firstWhere(
  (s) => s.name.toUpperCase() == value,
  orElse: () => TrainerGroupInvitationStatus.pending,
);

class TrainerGroupMember {
  const TrainerGroupMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final TrainerGroupMemberRole role;
  final DateTime joinedAt;
  final String? displayName;
  final String? avatarUrl;

  factory TrainerGroupMember.fromJson(Map<String, dynamic> json) {
    return TrainerGroupMember(
      userId: json['userId'] as String,
      role: trainerGroupMemberRoleFromJson(json['role'] as String),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

/// A Trainer group — see services/api/prisma/schema.prisma's Trainer
/// group comment and packages/docs/product/user-scenario-bible.md
/// Scenario 24. `memberLimit` and `isExpanded` are read from the
/// backend, never hard-coded here: a group's expanded (Premium) tier
/// follows its OWNER's subscription, not the viewer's — see
/// TrainerGroupsService's doc comment.
class TrainerGroup {
  const TrainerGroup({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    required this.memberLimit,
    required this.isExpanded,
    required this.isOwnGroup,
    required this.createdAt,
    required this.members,
  });

  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final int memberLimit;
  final bool isExpanded;
  final bool isOwnGroup;
  final DateTime createdAt;
  final List<TrainerGroupMember> members;

  factory TrainerGroup.fromJson(Map<String, dynamic> json) {
    return TrainerGroup(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      memberLimit: json['memberLimit'] as int,
      isExpanded: json['isExpanded'] as bool? ?? false,
      isOwnGroup: json['isOwnGroup'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      members: (json['members'] as List<dynamic>)
          .map((m) => TrainerGroupMember.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TrainerGroupInvitation {
  const TrainerGroupInvitation({
    required this.id,
    required this.groupId,
    required this.inviterId,
    required this.inviteeId,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String inviterId;
  final String inviteeId;
  final TrainerGroupInvitationStatus status;
  final DateTime createdAt;

  factory TrainerGroupInvitation.fromJson(Map<String, dynamic> json) {
    return TrainerGroupInvitation(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      inviterId: json['inviterId'] as String,
      inviteeId: json['inviteeId'] as String,
      status: trainerGroupInvitationStatusFromJson(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class TrainerGroupMessage {
  const TrainerGroupMessage({
    required this.id,
    required this.groupId,
    required this.authorId,
    this.body,
    this.imageUrl,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String authorId;
  final String? body;
  final String? imageUrl;
  final DateTime createdAt;

  factory TrainerGroupMessage.fromJson(Map<String, dynamic> json) {
    return TrainerGroupMessage(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      authorId: json['authorId'] as String,
      body: json['body'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class TrainerGroupSharedPlan {
  const TrainerGroupSharedPlan({
    required this.id,
    required this.sharedById,
    required this.createdAt,
    required this.workoutPlanId,
    required this.workoutPlanName,
    this.workoutPlanDescription,
  });

  final String id;
  final String sharedById;
  final DateTime createdAt;
  final String workoutPlanId;
  final String workoutPlanName;
  final String? workoutPlanDescription;

  factory TrainerGroupSharedPlan.fromJson(Map<String, dynamic> json) {
    final plan = json['workoutPlan'] as Map<String, dynamic>;
    return TrainerGroupSharedPlan(
      id: json['id'] as String,
      sharedById: json['sharedById'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      workoutPlanId: plan['id'] as String,
      workoutPlanName: plan['name'] as String,
      workoutPlanDescription: plan['description'] as String?,
    );
  }
}

/// A Premium-tier broadcast message (Build Session 9 Part 20) — only
/// postable by the group owner or a moderator, and only once the group
/// owner holds the expanded tier. See TrainerGroup.isExpanded.
class TrainerGroupAnnouncement {
  const TrainerGroupAnnouncement({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String authorId;
  final String body;
  final DateTime createdAt;

  factory TrainerGroupAnnouncement.fromJson(Map<String, dynamic> json) {
    return TrainerGroupAnnouncement(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      authorId: json['authorId'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

enum WorkoutAssignmentStatus { pending, accepted, completed, canceled }

WorkoutAssignmentStatus workoutAssignmentStatusFromJson(String value) =>
    WorkoutAssignmentStatus.values.firstWhere(
      (s) => s.name.toUpperCase() == value,
      orElse: () => WorkoutAssignmentStatus.pending,
    );

/// A trainer assigning one of their own workout plans to a group member
/// as a to-do (Build Session 12 Part 9). Accepting clones the exercises
/// into a brand-new plan the assignee owns — [assignedPlanId] is that
/// clone's id, present once [status] passes [WorkoutAssignmentStatus.pending].
/// [status] flips to [WorkoutAssignmentStatus.completed] automatically
/// the moment the assignee finishes a session against that cloned plan —
/// there is no "mark done" action to call.
class WorkoutAssignment {
  const WorkoutAssignment({
    required this.id,
    required this.groupId,
    required this.assignedById,
    required this.assigneeId,
    required this.sourcePlanId,
    required this.sourcePlanName,
    this.assignedPlanId,
    this.note,
    this.dueAt,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String groupId;
  final String assignedById;
  final String assigneeId;
  final String sourcePlanId;
  final String sourcePlanName;
  final String? assignedPlanId;
  final String? note;
  final DateTime? dueAt;
  final WorkoutAssignmentStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;

  factory WorkoutAssignment.fromJson(Map<String, dynamic> json) {
    return WorkoutAssignment(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      assignedById: json['assignedById'] as String,
      assigneeId: json['assigneeId'] as String,
      sourcePlanId: json['sourcePlanId'] as String,
      sourcePlanName: json['sourcePlanName'] as String,
      assignedPlanId: json['assignedPlanId'] as String?,
      note: json['note'] as String?,
      dueAt: json['dueAt'] != null
          ? DateTime.parse(json['dueAt'] as String)
          : null,
      status: workoutAssignmentStatusFromJson(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}

/// Building Session 13 Part 3's three real RSVP responses. Deliberately no
/// "invited"/"joined"/"completed" values — every group member is an
/// implicit invitee, and the server represents "hasn't responded" as no
/// row at all rather than a fourth status; see the backend schema comment
/// on TrainerGroupScheduledSessionParticipant.
enum ScheduledSessionRsvpStatus { going, maybe, declined }

extension ScheduledSessionRsvpStatusWire on ScheduledSessionRsvpStatus {
  String get wireValue => switch (this) {
    ScheduledSessionRsvpStatus.going => 'GOING',
    ScheduledSessionRsvpStatus.maybe => 'MAYBE',
    ScheduledSessionRsvpStatus.declined => 'DECLINED',
  };
}

ScheduledSessionRsvpStatus? scheduledSessionRsvpStatusFromJson(String? value) {
  switch (value) {
    case 'GOING':
      return ScheduledSessionRsvpStatus.going;
    case 'MAYBE':
      return ScheduledSessionRsvpStatus.maybe;
    case 'DECLINED':
      return ScheduledSessionRsvpStatus.declined;
    default:
      return null;
  }
}

/// UPCOMING/COMPLETED/CANCELED — always server-derived, never a status the
/// client sets; see the backend's deriveScheduledSessionStatus.
enum ScheduledSessionStatus { upcoming, completed, canceled }

ScheduledSessionStatus _scheduledSessionStatusFromJson(String? value) {
  switch (value) {
    case 'COMPLETED':
      return ScheduledSessionStatus.completed;
    case 'CANCELED':
      return ScheduledSessionStatus.canceled;
    default:
      return ScheduledSessionStatus.upcoming;
  }
}

/// A date/time-based booking for a group (Build Session 12 Part 10) —
/// distinct from a Joint Workout Session's invite-now/start-now flow.
/// Creating one requires the group owner's expanded (Premium) tier; any
/// member can view the upcoming list. Build Session 13 Part 3 added RSVP
/// counts/[viewerRsvpStatus] and an optional [workoutPlanId] preview —
/// starting the real-time session at meeting time reuses the existing
/// Joint Workout Session flow (`trainerGroupId`), not a new implementation.
class TrainerGroupScheduledSession {
  const TrainerGroupScheduledSession({
    required this.id,
    required this.groupId,
    required this.createdById,
    this.title,
    required this.scheduledAt,
    this.durationMinutes,
    this.location,
    this.videoLink,
    this.description,
    this.workoutPlanId,
    this.workoutPlanName,
    this.canceledAt,
    required this.createdAt,
    this.status = ScheduledSessionStatus.upcoming,
    this.goingCount = 0,
    this.maybeCount = 0,
    this.declinedCount = 0,
    this.viewerRsvpStatus,
  });

  final String id;
  final String groupId;
  final String createdById;
  final String? title;
  final DateTime scheduledAt;
  final int? durationMinutes;
  final String? location;
  final String? videoLink;
  final String? description;
  final String? workoutPlanId;
  final String? workoutPlanName;
  final DateTime? canceledAt;
  final DateTime createdAt;
  final ScheduledSessionStatus status;
  final int goingCount;
  final int maybeCount;
  final int declinedCount;
  final ScheduledSessionRsvpStatus? viewerRsvpStatus;

  factory TrainerGroupScheduledSession.fromJson(Map<String, dynamic> json) {
    return TrainerGroupScheduledSession(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      createdById: json['createdById'] as String,
      title: json['title'] as String?,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      durationMinutes: json['durationMinutes'] as int?,
      location: json['location'] as String?,
      videoLink: json['videoLink'] as String?,
      description: json['description'] as String?,
      workoutPlanId: json['workoutPlanId'] as String?,
      workoutPlanName: json['workoutPlanName'] as String?,
      canceledAt: json['canceledAt'] != null
          ? DateTime.parse(json['canceledAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: _scheduledSessionStatusFromJson(json['status'] as String?),
      goingCount: json['goingCount'] as int? ?? 0,
      maybeCount: json['maybeCount'] as int? ?? 0,
      declinedCount: json['declinedCount'] as int? ?? 0,
      viewerRsvpStatus: scheduledSessionRsvpStatusFromJson(
        json['viewerRsvpStatus'] as String?,
      ),
    );
  }
}

/// A read-only summary of one group a caller owns or moderates, for
/// [TrainerDashboard] (Build Session 12 Part 11).
class TrainerDashboardGroup {
  const TrainerDashboardGroup({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.pendingAssignmentCount,
  });

  final String id;
  final String name;
  final int memberCount;
  final int pendingAssignmentCount;

  factory TrainerDashboardGroup.fromJson(Map<String, dynamic> json) {
    return TrainerDashboardGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      memberCount: json['memberCount'] as int,
      pendingAssignmentCount: json['pendingAssignmentCount'] as int,
    );
  }
}

/// A read-only aggregate across every group the caller owns or
/// moderates (Build Session 12 Part 11) — composed entirely from
/// existing membership/assignment/scheduled-session data, no new write
/// model behind it.
class TrainerDashboard {
  const TrainerDashboard({
    required this.groups,
    required this.upcomingSessions,
    required this.recentAssignments,
  });

  final List<TrainerDashboardGroup> groups;
  final List<TrainerGroupScheduledSession> upcomingSessions;
  final List<WorkoutAssignment> recentAssignments;

  factory TrainerDashboard.fromJson(Map<String, dynamic> json) {
    return TrainerDashboard(
      groups: (json['groups'] as List<dynamic>)
          .map((g) => TrainerDashboardGroup.fromJson(g as Map<String, dynamic>))
          .toList(),
      upcomingSessions: (json['upcomingSessions'] as List<dynamic>)
          .map(
            (s) => TrainerGroupScheduledSession.fromJson(
              s as Map<String, dynamic>,
            ),
          )
          .toList(),
      recentAssignments: (json['recentAssignments'] as List<dynamic>)
          .map((a) => WorkoutAssignment.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}
