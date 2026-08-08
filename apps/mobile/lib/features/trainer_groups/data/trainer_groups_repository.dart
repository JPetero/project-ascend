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
}
