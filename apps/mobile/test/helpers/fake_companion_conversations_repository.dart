import 'package:mobile/features/companion/data/companion_conversations_repository.dart';
import 'package:mobile/features/companion/domain/companion_conversation.dart';
import 'package:mobile/features/profile/domain/preferences_model.dart';

/// In-memory stand-in for [CompanionConversationsRepository].
class FakeCompanionConversationsRepository
    implements CompanionConversationsRepository {
  FakeCompanionConversationsRepository({
    List<CompanionConversationDetail>? conversations,
  }) : conversations = conversations ?? [];

  final List<CompanionConversationDetail> conversations;

  @override
  Future<List<CompanionConversationSummary>> fetchConversations() async {
    final sorted = [...conversations]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted
        .map(
          (c) => CompanionConversationSummary(
            id: c.id,
            companion: c.companion,
            title: c.title,
            createdAt: c.createdAt,
            updatedAt: c.updatedAt,
            lastMessagePreview: c.lastMessagePreview,
          ),
        )
        .toList();
  }

  @override
  Future<CompanionConversationDetail> fetchConversation(String id) async {
    return conversations.firstWhere((c) => c.id == id);
  }

  @override
  Future<void> renameConversation(String id, String title) async {
    final index = conversations.indexWhere((c) => c.id == id);
    final existing = conversations[index];
    conversations[index] = CompanionConversationDetail(
      id: existing.id,
      companion: existing.companion,
      title: title,
      createdAt: existing.createdAt,
      updatedAt: existing.updatedAt,
      lastMessagePreview: existing.lastMessagePreview,
      messages: existing.messages,
    );
  }

  @override
  Future<void> deleteConversation(String id) async {
    conversations.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> clearConversations() async => conversations.clear();
}

CompanionConversationDetail sampleConversation({
  String id = 'conversation-1',
  Companion companion = Companion.atlas,
  String? title,
  DateTime? createdAt,
  DateTime? updatedAt,
  String? lastMessagePreview = 'How was your run today?',
  List<CompanionConversationMessage>? messages,
}) {
  final created = createdAt ?? DateTime.utc(2026, 8, 9);
  return CompanionConversationDetail(
    id: id,
    companion: companion,
    title: title,
    createdAt: created,
    updatedAt: updatedAt ?? created,
    lastMessagePreview: lastMessagePreview,
    messages:
        messages ??
        [
          CompanionConversationMessage(
            id: 'message-1',
            isFromUser: true,
            text: 'How should I structure my week?',
            createdAt: created,
          ),
          CompanionConversationMessage(
            id: 'message-2',
            isFromUser: false,
            text: 'How was your run today?',
            createdAt: created,
          ),
        ],
  );
}
