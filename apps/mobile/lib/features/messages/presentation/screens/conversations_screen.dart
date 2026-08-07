import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/conversation.dart';
import '../providers/conversation_detail_controller.dart';
import '../providers/conversations_controller.dart';

/// Conversation list — Build Session 8 Part 8. Message requests
/// (PENDING conversations someone else started) are shown alongside
/// accepted threads with a "Request" label rather than a separate tab,
/// since the list is short enough not to need one. Polls on its own
/// widget-owned timer (rather than one living inside the provider) so
/// the timer is reliably canceled with the screen — see
/// [ConversationsController]'s doc comment.
class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      ref
          .read(conversationsControllerProvider.notifier)
          .refresh(silently: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationsControllerProvider);
    final controller = ref.read(conversationsControllerProvider.notifier);
    final myUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: _buildBody(context, state, controller, myUserId),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ConversationsState state,
    ConversationsController controller,
    String? myUserId,
  ) {
    if (state.isLoading && state.conversations.isEmpty) {
      return const AscendLoadingIndicator();
    }
    if (state.conversations.isEmpty) {
      return const AscendEmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No conversations yet',
        message:
            'Message a friend from their profile, or start with a request from Find.',
      );
    }
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(AscendSpacing.md),
        itemCount: state.conversations.length,
        separatorBuilder: (_, _) => const SizedBox(height: AscendSpacing.sm),
        itemBuilder: (context, index) {
          final conversation = state.conversations[index];
          return _ConversationTile(
            conversation: conversation,
            isRequestReceived:
                conversation.status == ConversationStatus.pending &&
                conversation.initiatorId != myUserId,
          );
        },
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({
    required this.conversation,
    required this.isRequestReceived,
  });

  final Conversation conversation;
  final bool isRequestReceived;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUserId = conversation.otherUserId;
    final profileAsync = otherUserId != null
        ? ref.watch(conversationProfileProvider(otherUserId))
        : null;
    final displayName = profileAsync?.value?.displayName ?? 'Ascend member';
    final avatarUrl = profileAsync?.value?.avatarUrl;

    return AscendCard(
      onTap: () => context.push(
        RoutePaths.conversationDetailPath(conversation.id),
        extra: otherUserId,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null ? const Icon(Icons.person_outline) : null,
          ),
          const SizedBox(width: AscendSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isRequestReceived) const Chip(label: Text('Request')),
                  ],
                ),
                if (conversation.lastMessage?.body != null)
                  Text(
                    conversation.lastMessage!.body!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (conversation.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: AscendSpacing.sm),
              child: CircleAvatar(
                radius: 10,
                child: Text(
                  '${conversation.unreadCount}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          if (conversation.isMuted)
            const Padding(
              padding: EdgeInsets.only(left: AscendSpacing.xs),
              child: Icon(Icons.notifications_off_outlined, size: 16),
            ),
        ],
      ),
    );
  }
}
