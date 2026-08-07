import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/messages_repository.dart';
import '../../domain/conversation.dart';
import '../../domain/direct_message.dart';
import 'conversations_controller.dart';

class ConversationDetailState {
  const ConversationDetailState({
    this.messages = const [],
    this.status = ConversationStatus.accepted,
    this.initiatorId,
    this.otherUserId,
    this.isMuted = false,
    this.isLoading = true,
    this.isSending = false,
    this.error,
  });

  /// Oldest first, ready to render top-to-bottom in a chat thread.
  final List<DirectMessage> messages;
  final ConversationStatus status;
  final String? initiatorId;
  final String? otherUserId;
  final bool isMuted;
  final bool isLoading;
  final bool isSending;
  final String? error;

  bool isInitiator(String? currentUserId) =>
      initiatorId != null && initiatorId == currentUserId;

  ConversationDetailState copyWith({
    List<DirectMessage>? messages,
    ConversationStatus? status,
    String? initiatorId,
    String? otherUserId,
    bool? isMuted,
    bool? isLoading,
    bool? isSending,
    String? error,
  }) {
    return ConversationDetailState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      initiatorId: initiatorId ?? this.initiatorId,
      otherUserId: otherUserId ?? this.otherUserId,
      isMuted: isMuted ?? this.isMuted,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

/// Drives a single conversation thread — Build Session 8 Part 8.
/// [ConversationDetailScreen] polls [refresh] on its own widget-owned
/// timer for new messages rather than requiring the [MessagesGateway]
/// WebSocket connection, per the backend's "database-first, realtime is
/// a convenience layer" design.
class ConversationDetailController
    extends StateNotifier<ConversationDetailState> {
  ConversationDetailController({
    required MessagesRepository repository,
    required this.conversationId,
    String? initialOtherUserId,
  }) : _repository = repository,
       super(ConversationDetailState(otherUserId: initialOtherUserId)) {
    refresh();
  }

  final MessagesRepository _repository;
  final String conversationId;

  Future<void> refresh({bool silently = false}) async {
    if (!silently) state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _repository.getMessages(conversationId),
        _repository.listConversations(),
      ]);
      final newestFirst = results[0] as List<DirectMessage>;
      final conversations = results[1] as List<Conversation>;
      final summary = conversations
          .where((c) => c.id == conversationId)
          .cast<Conversation?>()
          .firstWhere((_) => true, orElse: () => null);

      state = state.copyWith(
        messages: newestFirst.reversed.toList(),
        status: summary?.status ?? state.status,
        initiatorId: summary?.initiatorId,
        otherUserId: summary?.otherUserId,
        isMuted: summary?.isMuted ?? state.isMuted,
        isLoading: false,
      );

      if ((summary?.unreadCount ?? 0) > 0) {
        await _repository.markRead(conversationId);
      }
    } catch (error) {
      if (silently) return;
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<bool> sendMessage(String body) async {
    if (body.trim().isEmpty) return false;
    state = state.copyWith(isSending: true, error: null);
    try {
      await _repository.sendMessage(conversationId, body: body.trim());
      await refresh();
      state = state.copyWith(isSending: false);
      return true;
    } catch (error) {
      state = state.copyWith(isSending: false, error: error.toString());
      return false;
    }
  }

  Future<void> accept() async {
    await _repository.acceptConversation(conversationId);
    await refresh();
  }

  Future<void> decline() async {
    await _repository.declineConversation(conversationId);
    await refresh();
  }

  Future<void> setMuted(bool muted) async {
    await _repository.setMuted(conversationId, muted);
    await refresh();
  }

  Future<void> reportMessage(String messageId, String reason) async {
    await _repository.reportMessage(messageId, reason);
  }
}

class ConversationDetailParams {
  const ConversationDetailParams({
    required this.conversationId,
    this.otherUserId,
  });

  final String conversationId;
  final String? otherUserId;

  @override
  bool operator ==(Object other) =>
      other is ConversationDetailParams &&
      other.conversationId == conversationId;

  @override
  int get hashCode => conversationId.hashCode;
}

final conversationDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<
      ConversationDetailController,
      ConversationDetailState,
      ConversationDetailParams
    >((ref, params) {
      return ConversationDetailController(
        repository: ref.watch(messagesRepositoryProvider),
        conversationId: params.conversationId,
        initialOtherUserId: params.otherUserId,
      );
    });

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authControllerProvider.select((s) => s.user?.id));
});
