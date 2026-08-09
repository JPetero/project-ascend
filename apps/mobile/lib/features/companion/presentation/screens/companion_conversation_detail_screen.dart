import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../providers/companion_conversations_controller.dart';

/// A read-only view of one saved conversation (Build Session 12 Part 8)
/// — reopening a past conversation shows exactly what was said, but
/// doesn't currently resume it as the live/active chat session (that
/// would mean threading a conversation id through the live chat
/// controller, a larger follow-up left for a future session; see
/// build-session-12.md).
class CompanionConversationDetailScreen extends ConsumerWidget {
  const CompanionConversationDetailScreen({
    super.key,
    required this.conversationId,
  });

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(
      companionConversationDetailProvider(conversationId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Conversation')),
      body: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const AscendEmptyState(
            icon: Icons.error_outline,
            title: "Couldn't load this conversation",
            message: 'It may have been deleted.',
          ),
          data: (conversation) => ListView.builder(
            padding: const EdgeInsets.all(AscendSpacing.md),
            itemCount: conversation.messages.length,
            itemBuilder: (context, index) {
              final message = conversation.messages[index];
              return _TranscriptBubble(
                text: message.text,
                isFromUser: message.isFromUser,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TranscriptBubble extends StatelessWidget {
  const _TranscriptBubble({required this.text, required this.isFromUser});

  final String text;
  final bool isFromUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: AscendSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AscendSpacing.md,
          vertical: AscendSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isFromUser
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AscendRadius.large),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isFromUser
                ? colorScheme.onPrimary
                : theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }
}
