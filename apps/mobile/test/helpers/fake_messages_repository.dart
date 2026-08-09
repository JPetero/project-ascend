import 'package:mobile/core/errors/app_exception.dart';
import 'package:mobile/features/messages/data/messages_repository.dart';
import 'package:mobile/features/messages/domain/conversation.dart';
import 'package:mobile/features/messages/domain/direct_message.dart';

DirectMessage sampleDirectMessage({
  String id = 'message-1',
  String conversationId = 'conv-1',
  String senderId = 'sender-1',
  String? body = 'Hello there',
  DateTime? createdAt,
}) {
  return DirectMessage(
    id: id,
    conversationId: conversationId,
    senderId: senderId,
    type: DirectMessageType.text,
    body: body,
    createdAt: createdAt ?? DateTime.utc(2026, 8, 7),
  );
}

Conversation sampleConversation({
  String id = 'conv-1',
  ConversationStatus status = ConversationStatus.accepted,
  String initiatorId = 'me',
  String? otherUserId = 'friend-1',
  DirectMessage? lastMessage,
  int unreadCount = 0,
  bool isMuted = false,
}) {
  return Conversation(
    id: id,
    status: status,
    initiatorId: initiatorId,
    otherUserId: otherUserId,
    lastMessage: lastMessage,
    unreadCount: unreadCount,
    isMuted: isMuted,
  );
}

/// In-memory stand-in for [MessagesRepository].
class FakeMessagesRepository implements MessagesRepository {
  FakeMessagesRepository({List<Conversation>? conversations})
    : conversations = conversations ?? [];

  final List<Conversation> conversations;
  final Map<String, List<DirectMessage>> messagesByConversation = {};
  String? lastSentBody;
  String? lastReportedMessageId;
  String? lastReportReason;
  int _messageCounter = 0;

  /// Set to simulate a stale/unauthorized/deleted conversation target
  /// (Build Session 11 Part 6) — [getMessages] throws this instead of
  /// returning, matching the backend's 404 for a conversation the caller
  /// isn't a participant of or that no longer exists.
  AppException? getMessagesError;

  @override
  Future<int> unreadCount() async =>
      conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);

  @override
  Future<List<Conversation>> listConversations() async =>
      List.unmodifiable(conversations);

  @override
  Future<Conversation> startConversation(String recipientId) async {
    final existing = conversations.where((c) => c.otherUserId == recipientId);
    if (existing.isNotEmpty) return existing.first;
    final conversation = sampleConversation(
      id: 'conv-${conversations.length + 1}',
      otherUserId: recipientId,
    );
    conversations.add(conversation);
    return conversation;
  }

  @override
  Future<List<DirectMessage>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 30,
  }) async {
    if (getMessagesError != null) throw getMessagesError!;
    final messages = messagesByConversation[conversationId] ?? [];
    // Fake mirrors the backend's newest-first ordering.
    return messages.reversed.toList();
  }

  @override
  Future<DirectMessage> sendMessage(
    String conversationId, {
    String? body,
    String? replyToId,
    List<String>? mediaAssetIds,
  }) async {
    lastSentBody = body;
    _messageCounter += 1;
    final message = sampleDirectMessage(
      id: 'message-$_messageCounter',
      conversationId: conversationId,
      senderId: 'me',
      body: body,
    );
    messagesByConversation.putIfAbsent(conversationId, () => []).add(message);
    return message;
  }

  @override
  Future<void> markRead(String conversationId) async {
    final index = conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) return;
    conversations[index] = Conversation(
      id: conversations[index].id,
      status: conversations[index].status,
      initiatorId: conversations[index].initiatorId,
      otherUserId: conversations[index].otherUserId,
      lastMessage: conversations[index].lastMessage,
      unreadCount: 0,
      isMuted: conversations[index].isMuted,
    );
  }

  @override
  Future<void> setMuted(String conversationId, bool muted) async {
    final index = conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) return;
    conversations[index] = Conversation(
      id: conversations[index].id,
      status: conversations[index].status,
      initiatorId: conversations[index].initiatorId,
      otherUserId: conversations[index].otherUserId,
      lastMessage: conversations[index].lastMessage,
      unreadCount: conversations[index].unreadCount,
      isMuted: muted,
    );
  }

  @override
  Future<void> deleteForSelf(String conversationId) async {
    conversations.removeWhere((c) => c.id == conversationId);
  }

  @override
  Future<Conversation> acceptConversation(String conversationId) async {
    final index = conversations.indexWhere((c) => c.id == conversationId);
    final updated = Conversation(
      id: conversations[index].id,
      status: ConversationStatus.accepted,
      initiatorId: conversations[index].initiatorId,
      otherUserId: conversations[index].otherUserId,
      lastMessage: conversations[index].lastMessage,
      unreadCount: conversations[index].unreadCount,
      isMuted: conversations[index].isMuted,
    );
    conversations[index] = updated;
    return updated;
  }

  @override
  Future<Conversation> declineConversation(String conversationId) async {
    final index = conversations.indexWhere((c) => c.id == conversationId);
    final updated = Conversation(
      id: conversations[index].id,
      status: ConversationStatus.declined,
      initiatorId: conversations[index].initiatorId,
      otherUserId: conversations[index].otherUserId,
      lastMessage: conversations[index].lastMessage,
      unreadCount: conversations[index].unreadCount,
      isMuted: conversations[index].isMuted,
    );
    conversations[index] = updated;
    return updated;
  }

  @override
  Future<void> reportMessage(String messageId, String reason) async {
    lastReportedMessageId = messageId;
    lastReportReason = reason;
  }
}
