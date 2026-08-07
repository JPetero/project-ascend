enum TrainerGroupMemberRole { owner, member }

TrainerGroupMemberRole trainerGroupMemberRoleFromJson(String value) =>
    TrainerGroupMemberRole.values.firstWhere(
      (r) => r.name.toUpperCase() == value,
      orElse: () => TrainerGroupMemberRole.member,
    );

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

/// A free-tier Trainer group — see
/// services/api/prisma/schema.prisma's Trainer group comment and
/// packages/docs/product/user-scenario-bible.md Scenario 24.
/// `memberLimit` is read from the backend's single source of truth
/// (common/policy/trainer-group-policy.ts), never hard-coded here.
class TrainerGroup {
  const TrainerGroup({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    required this.memberLimit,
    required this.isOwnGroup,
    required this.createdAt,
    required this.members,
  });

  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final int memberLimit;
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
