import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/companion_conversations_repository.dart';
import '../../domain/companion_conversation.dart';

final companionConversationsRepositoryProvider =
    Provider<CompanionConversationsRepository>((ref) {
      return CompanionConversationsRepository(
        apiClient: ref.watch(apiClientProvider),
      );
    });

/// One saved conversation's full transcript, for
/// `CompanionConversationDetailScreen`. `.family` keyed by conversation
/// id, `.autoDispose` since a viewer only cares about it while the
/// detail screen is open.
final companionConversationDetailProvider = FutureProvider.autoDispose
    .family<CompanionConversationDetail, String>((ref, conversationId) {
      return ref
          .watch(companionConversationsRepositoryProvider)
          .fetchConversation(conversationId);
    });

class CompanionConversationsState {
  const CompanionConversationsState({
    this.conversations = const [],
    this.isLoading = true,
    this.error,
  });

  final List<CompanionConversationSummary> conversations;
  final bool isLoading;
  final String? error;

  CompanionConversationsState copyWith({
    List<CompanionConversationSummary>? conversations,
    bool? isLoading,
    String? error,
  }) {
    return CompanionConversationsState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Backs the "manage conversation history" screen reachable from the
/// "Conversation history" toggle in dashboard_screen.dart (Build Session
/// 12 Part 8) — deliberately separate from
/// `CompanionMemoryController`/`CompanionMemoryScreen`.
class CompanionConversationsController
    extends StateNotifier<CompanionConversationsState> {
  CompanionConversationsController({
    required CompanionConversationsRepository repository,
  }) : _repository = repository,
       super(const CompanionConversationsState()) {
    refresh();
  }

  final CompanionConversationsRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final conversations = await _repository.fetchConversations();
      state = CompanionConversationsState(
        conversations: conversations,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> rename(String id, String title) async {
    await _repository.renameConversation(id, title);
    await refresh();
  }

  Future<void> delete(String id) async {
    await _repository.deleteConversation(id);
    state = state.copyWith(
      conversations: state.conversations
          .where((conversation) => conversation.id != id)
          .toList(),
    );
  }

  Future<void> clear() async {
    await _repository.clearConversations();
    state = state.copyWith(conversations: const []);
  }
}

final companionConversationsControllerProvider =
    StateNotifierProvider<
      CompanionConversationsController,
      CompanionConversationsState
    >((ref) {
      return CompanionConversationsController(
        repository: ref.watch(companionConversationsRepositoryProvider),
      );
    });
