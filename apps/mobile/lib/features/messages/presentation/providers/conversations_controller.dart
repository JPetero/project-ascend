import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../community/domain/community_profile.dart';
import '../../../community/presentation/providers/community_feed_controller.dart'
    show communityRepositoryProvider;
import '../../data/messages_repository.dart';
import '../../domain/conversation.dart';

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return MessagesRepository(apiClient: ref.watch(apiClientProvider));
});

/// Conversations only carry the other participant's user id, not their
/// profile — resolved lazily here rather than bloating every
/// conversation payload with profile data most callers won't render.
final conversationProfileProvider = FutureProvider.autoDispose
    .family<CommunityProfile?, String>((ref, userId) async {
      final repository = ref.watch(communityRepositoryProvider);
      try {
        return await repository.getProfile(userId);
      } catch (_) {
        return null;
      }
    });

class ConversationsState {
  const ConversationsState({
    this.conversations = const [],
    this.unreadCount = 0,
    this.isLoading = true,
    this.error,
  });

  final List<Conversation> conversations;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  ConversationsState copyWith({
    List<Conversation>? conversations,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Drives the conversation list and unread badge — Build Session 8 Part
/// 8. The server's [MessagesGateway] WebSocket push is a convenience
/// layer only; durability comes from this state being backed by plain
/// REST calls. [ConversationsScreen] polls [refresh] on its own widget-
/// owned timer (this state is shared, so the badge shown elsewhere —
/// e.g. the Community tab — updates for free whenever that happens).
class ConversationsController extends StateNotifier<ConversationsState> {
  ConversationsController({required MessagesRepository repository})
    : _repository = repository,
      super(const ConversationsState()) {
    refresh();
  }

  final MessagesRepository _repository;

  Future<void> refresh({bool silently = false}) async {
    if (!silently) state = state.copyWith(isLoading: true, error: null);
    try {
      final conversations = await _repository.listConversations();
      final unread = conversations.fold<int>(
        0,
        (sum, c) => sum + c.unreadCount,
      );
      state = ConversationsState(
        conversations: conversations,
        unreadCount: unread,
        isLoading: false,
      );
    } catch (error) {
      if (silently) return;
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<Conversation> startConversation(String recipientId) async {
    final conversation = await _repository.startConversation(recipientId);
    await refresh();
    return conversation;
  }

  Future<void> setMuted(String conversationId, bool muted) async {
    await _repository.setMuted(conversationId, muted);
    await refresh();
  }

  Future<void> deleteForSelf(String conversationId) async {
    await _repository.deleteForSelf(conversationId);
    await refresh();
  }
}

final conversationsControllerProvider =
    StateNotifierProvider<ConversationsController, ConversationsState>((ref) {
      return ConversationsController(
        repository: ref.watch(messagesRepositoryProvider),
      );
    });
