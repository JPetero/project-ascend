import '../../../core/networking/api_client.dart';
import '../../community/domain/community_profile.dart';
import '../domain/friend_request.dart';

/// Thin client for services/api/src/modules/friends — Build Session 8
/// Part 7's real mutual-friendship system, deliberately separate from
/// Community's one-directional Follow.
class FriendsRepository {
  FriendsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<CommunityProfile>> searchUsers(String query) async {
    final envelope = await _apiClient.get(
      '/friends/search',
      (data) => data as List<dynamic>,
      query: {'query': query},
    );
    return envelope.data!
        .map((p) => CommunityProfile.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<List<CommunityProfile>> listFriends() async {
    final envelope = await _apiClient.get(
      '/friends',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map((p) => CommunityProfile.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<int> friendCount() async {
    final envelope = await _apiClient.get(
      '/friends/count',
      (data) => data as int,
    );
    return envelope.data!;
  }

  Future<List<FriendRequest>> listIncomingRequests() async {
    final envelope = await _apiClient.get(
      '/friends/requests/incoming',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map((r) => FriendRequest.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<FriendRequest>> listOutgoingRequests() async {
    final envelope = await _apiClient.get(
      '/friends/requests/outgoing',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map((r) => FriendRequest.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<FriendRequest> sendRequest(String recipientId) async {
    final envelope = await _apiClient.post(
      '/friends/requests',
      (data) => data as Map<String, dynamic>,
      data: {'recipientId': recipientId},
    );
    return FriendRequest.fromJson(envelope.data!);
  }

  Future<void> acceptRequest(String requestId) async {
    await _apiClient.post('/friends/requests/$requestId/accept', (_) => null);
  }

  Future<void> declineRequest(String requestId) async {
    await _apiClient.post('/friends/requests/$requestId/decline', (_) => null);
  }

  Future<void> cancelRequest(String requestId) async {
    await _apiClient.post('/friends/requests/$requestId/cancel', (_) => null);
  }

  Future<void> removeFriend(String friendId) async {
    await _apiClient.delete('/friends/$friendId', (_) => null);
  }
}
