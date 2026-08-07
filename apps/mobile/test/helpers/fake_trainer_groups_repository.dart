import 'package:mobile/features/trainer_groups/data/trainer_groups_repository.dart';
import 'package:mobile/features/trainer_groups/domain/trainer_group.dart';

TrainerGroup sampleGroup({
  String id = 'group-1',
  String ownerId = 'owner-1',
  String name = 'Morning Crew',
  int memberLimit = 5,
  bool isOwnGroup = false,
  List<TrainerGroupMember>? members,
}) {
  return TrainerGroup(
    id: id,
    ownerId: ownerId,
    name: name,
    memberLimit: memberLimit,
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
  final List<({String groupId, String inviteeUserId})> invitesSent = [];

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
      isOwnGroup: group.isOwnGroup,
      createdAt: group.createdAt,
      members: group.members.where((m) => m.userId != userId).toList(),
    );
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
}
