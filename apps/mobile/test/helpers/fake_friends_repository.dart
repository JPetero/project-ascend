import 'package:mobile/features/community/domain/community_profile.dart';
import 'package:mobile/features/friends/data/friends_repository.dart';
import 'package:mobile/features/friends/domain/friend_request.dart';

FriendRequest sampleFriendRequest({
  String id = 'request-1',
  String senderId = 'sender-1',
  String recipientId = 'recipient-1',
  FriendRequestStatus status = FriendRequestStatus.pending,
}) {
  return FriendRequest(
    id: id,
    senderId: senderId,
    recipientId: recipientId,
    status: status,
    createdAt: DateTime.utc(2026, 8, 7),
  );
}

/// In-memory stand-in for [FriendsRepository].
class FakeFriendsRepository implements FriendsRepository {
  FakeFriendsRepository({
    List<CommunityProfile>? friends,
    List<CommunityProfile>? searchable,
    List<FriendRequest>? incoming,
    List<FriendRequest>? outgoing,
  }) : friends = friends ?? [],
       searchable = searchable ?? [],
       incoming = incoming ?? [],
       outgoing = outgoing ?? [];

  final List<CommunityProfile> friends;
  final List<CommunityProfile> searchable;
  final List<FriendRequest> incoming;
  final List<FriendRequest> outgoing;
  String? lastSentTo;

  @override
  Future<List<CommunityProfile>> searchUsers(String query) async {
    return searchable
        .where((p) => p.displayName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<List<CommunityProfile>> listFriends() async =>
      List.unmodifiable(friends);

  @override
  Future<int> friendCount() async => friends.length;

  @override
  Future<List<FriendRequest>> listIncomingRequests() async =>
      List.unmodifiable(incoming);

  @override
  Future<List<FriendRequest>> listOutgoingRequests() async =>
      List.unmodifiable(outgoing);

  @override
  Future<FriendRequest> sendRequest(String recipientId) async {
    lastSentTo = recipientId;
    final request = sampleFriendRequest(
      id: 'request-${outgoing.length}',
      recipientId: recipientId,
    );
    outgoing.add(request);
    return request;
  }

  @override
  Future<void> acceptRequest(String requestId) async {
    final request = incoming.firstWhere((r) => r.id == requestId);
    incoming.removeWhere((r) => r.id == requestId);
    friends.add(
      CommunityProfile(userId: request.senderId, displayName: 'New friend'),
    );
  }

  @override
  Future<void> declineRequest(String requestId) async {
    incoming.removeWhere((r) => r.id == requestId);
  }

  @override
  Future<void> cancelRequest(String requestId) async {
    outgoing.removeWhere((r) => r.id == requestId);
  }

  @override
  Future<void> removeFriend(String friendId) async {
    friends.removeWhere((f) => f.userId == friendId);
  }
}
