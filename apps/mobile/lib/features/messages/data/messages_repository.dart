import '../../../core/networking/api_client.dart';
import '../domain/conversation.dart';
import '../domain/direct_message.dart';

/// Thin client for services/api/src/modules/messages — Build Session 8
/// Part 8's 1:1 direct messaging. Realtime delivery is handled separately
/// by [MessagesGateway]'s WebSocket push (a convenience layer only); this
/// repository's REST calls are what keeps messages durable even if no
/// socket connection is ever established.
class MessagesRepository {
  MessagesRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<int> unreadCount() async {
    final envelope = await _apiClient.get(
      '/messages/unread-count',
      (data) => data as int,
    );
    return envelope.data!;
  }

  Future<List<Conversation>> listConversations() async {
    final envelope = await _apiClient.get(
      '/messages/conversations',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map((c) => Conversation.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<Conversation> startConversation(String recipientId) async {
    final envelope = await _apiClient.post(
      '/messages/conversations',
      (data) => data as Map<String, dynamic>,
      data: {'recipientId': recipientId},
    );
    return Conversation.fromJson(envelope.data!);
  }

  /// Newest-first, matching the backend's ordering.
  Future<List<DirectMessage>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 30,
  }) async {
    final envelope = await _apiClient.get(
      '/messages/conversations/$conversationId/messages',
      (data) => data as List<dynamic>,
      query: {'page': page, 'limit': limit},
    );
    return envelope.data!
        .map((m) => DirectMessage.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<DirectMessage> sendMessage(
    String conversationId, {
    String? body,
    String? replyToId,
    List<String>? mediaAssetIds,
  }) async {
    final envelope = await _apiClient.post(
      '/messages/conversations/$conversationId/messages',
      (data) => data as Map<String, dynamic>,
      data: {
        'body': ?body,
        'replyToId': ?replyToId,
        'mediaAssetIds': ?mediaAssetIds,
      },
    );
    return DirectMessage.fromJson(envelope.data!);
  }

  Future<void> markRead(String conversationId) async {
    await _apiClient.post(
      '/messages/conversations/$conversationId/read',
      (_) => null,
    );
  }

  Future<void> setMuted(String conversationId, bool muted) async {
    await _apiClient.patch(
      '/messages/conversations/$conversationId/mute',
      (_) => null,
      data: {'muted': muted},
    );
  }

  Future<void> deleteForSelf(String conversationId) async {
    await _apiClient.delete(
      '/messages/conversations/$conversationId',
      (_) => null,
    );
  }

  Future<Conversation> acceptConversation(String conversationId) async {
    final envelope = await _apiClient.post(
      '/messages/conversations/$conversationId/accept',
      (data) => data as Map<String, dynamic>,
    );
    return Conversation.fromJson(envelope.data!);
  }

  Future<Conversation> declineConversation(String conversationId) async {
    final envelope = await _apiClient.post(
      '/messages/conversations/$conversationId/decline',
      (data) => data as Map<String, dynamic>,
    );
    return Conversation.fromJson(envelope.data!);
  }

  Future<void> reportMessage(String messageId, String reason) async {
    await _apiClient.post(
      '/messages/$messageId/report',
      (_) => null,
      data: {'reason': reason},
    );
  }
}
