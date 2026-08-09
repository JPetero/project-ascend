import '../../../core/networking/api_client.dart';
import '../domain/companion_conversation.dart';

/// Thin client for `GET/PATCH/DELETE /assistant/conversations` (Build
/// Session 12 Part 8) — the real, inspectable surface behind the
/// "Conversation history" toggle in dashboard_screen.dart, deliberately
/// separate from `CompanionMemoryRepository`.
class CompanionConversationsRepository {
  CompanionConversationsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<CompanionConversationSummary>> fetchConversations() async {
    final envelope = await _apiClient.get(
      '/assistant/conversations',
      (data) => data as Map<String, dynamic>,
    );
    final conversations =
        envelope.data?['conversations'] as List<dynamic>? ?? const [];
    return conversations
        .cast<Map<String, dynamic>>()
        .map(CompanionConversationSummary.fromJson)
        .toList();
  }

  Future<CompanionConversationDetail> fetchConversation(String id) async {
    final envelope = await _apiClient.get(
      '/assistant/conversations/$id',
      (data) => data as Map<String, dynamic>,
    );
    return CompanionConversationDetail.fromJson(envelope.data!);
  }

  Future<void> renameConversation(String id, String title) async {
    await _apiClient.patch(
      '/assistant/conversations/$id',
      (_) => null,
      data: {'title': title},
    );
  }

  Future<void> deleteConversation(String id) async {
    await _apiClient.delete('/assistant/conversations/$id', (_) => null);
  }

  Future<void> clearConversations() async {
    await _apiClient.delete('/assistant/conversations', (_) => null);
  }
}
