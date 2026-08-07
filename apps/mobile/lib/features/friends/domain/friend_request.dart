enum FriendRequestStatus { pending, accepted, declined, canceled, expired }

FriendRequestStatus friendRequestStatusFromJson(String value) {
  switch (value) {
    case 'ACCEPTED':
      return FriendRequestStatus.accepted;
    case 'DECLINED':
      return FriendRequestStatus.declined;
    case 'CANCELED':
      return FriendRequestStatus.canceled;
    case 'EXPIRED':
      return FriendRequestStatus.expired;
    default:
      return FriendRequestStatus.pending;
  }
}

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String recipientId;
  final FriendRequestStatus status;
  final DateTime createdAt;

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      recipientId: json['recipientId'] as String,
      status: friendRequestStatusFromJson(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
