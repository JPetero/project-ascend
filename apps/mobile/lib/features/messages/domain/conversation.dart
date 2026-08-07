import 'direct_message.dart';

enum ConversationStatus { pending, accepted, declined }

ConversationStatus conversationStatusFromJson(String value) {
  switch (value) {
    case 'ACCEPTED':
      return ConversationStatus.accepted;
    case 'DECLINED':
      return ConversationStatus.declined;
    default:
      return ConversationStatus.pending;
  }
}

class Conversation {
  const Conversation({
    required this.id,
    required this.status,
    required this.initiatorId,
    this.otherUserId,
    this.lastMessage,
    required this.unreadCount,
    required this.isMuted,
  });

  final String id;
  final ConversationStatus status;
  final String initiatorId;
  final String? otherUserId;
  final DirectMessage? lastMessage;
  final int unreadCount;
  final bool isMuted;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final lastMessageJson = json['lastMessage'] as Map<String, dynamic>?;
    return Conversation(
      id: json['id'] as String,
      status: conversationStatusFromJson(json['status'] as String),
      initiatorId: json['initiatorId'] as String,
      otherUserId: json['otherUserId'] as String?,
      lastMessage: lastMessageJson != null
          ? DirectMessage.fromJson(lastMessageJson)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      isMuted: json['isMuted'] as bool? ?? false,
    );
  }
}
