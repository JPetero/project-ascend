import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/conversation.dart';
import '../../domain/direct_message.dart';
import '../providers/conversation_detail_controller.dart';
import '../providers/conversations_controller.dart';

/// One conversation thread — Build Session 8 Part 8. A PENDING request
/// the caller received shows accept/decline actions instead of a
/// composer until it's resolved, matching the backend's rule that only
/// the initiator may send while pending (and only once).
class ConversationDetailScreen extends ConsumerStatefulWidget {
  const ConversationDetailScreen({
    super.key,
    required this.conversationId,
    this.otherUserId,
  });

  final String conversationId;
  final String? otherUserId;

  @override
  ConsumerState<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState
    extends ConsumerState<ConversationDetailScreen> {
  final _bodyController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;

  ConversationDetailParams get _params => ConversationDetailParams(
    conversationId: widget.conversationId,
    otherUserId: widget.otherUserId,
  );

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref
          .read(conversationDetailControllerProvider(_params).notifier)
          .refresh(silently: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _bodyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationDetailControllerProvider(_params));
    final controller = ref.read(
      conversationDetailControllerProvider(_params).notifier,
    );
    final myUserId = ref.watch(currentUserIdProvider);
    final otherUserId = state.otherUserId ?? widget.otherUserId;
    final profile = otherUserId != null
        ? ref.watch(conversationProfileProvider(otherUserId)).value
        : null;

    final isPendingRequestToMe =
        state.status == ConversationStatus.pending &&
        !state.isInitiator(myUserId);
    final isPendingWaitingOnThem =
        state.status == ConversationStatus.pending &&
        state.isInitiator(myUserId);
    final isDeclined = state.status == ConversationStatus.declined;

    return Scaffold(
      appBar: AppBar(
        title: Text(profile?.displayName ?? 'Conversation'),
        actions: [
          IconButton(
            icon: Icon(
              state.isMuted
                  ? Icons.notifications_off
                  : Icons.notifications_none,
            ),
            tooltip: state.isMuted ? 'Unmute' : 'Mute',
            onPressed: () => controller.setMuted(!state.isMuted),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (isPendingRequestToMe)
              _RequestBanner(
                onAccept: controller.accept,
                onDecline: controller.decline,
              ),
            if (isPendingWaitingOnThem)
              const _InfoBanner(
                message:
                    'Message request sent. You can send one message '
                    'until they respond.',
              ),
            if (isDeclined)
              const _InfoBanner(message: 'This request was declined.'),
            Expanded(
              child: state.isLoading && state.messages.isEmpty
                  ? const AscendLoadingIndicator()
                  // A stale, unauthorized, or deleted conversation target
                  // (e.g. a push notification tapped after the thread was
                  // removed) fails to load rather than returning an empty
                  // history — distinct from a brand-new conversation with
                  // no error and no messages yet, which still gets the
                  // "Say hello" state below (Build Session 11 Part 6).
                  : state.error != null && state.messages.isEmpty
                  ? AscendEmptyState(
                      icon: Icons.error_outline,
                      title: 'Conversation not available',
                      message:
                          state.error ??
                          'This conversation may have been removed.',
                    )
                  : state.messages.isEmpty
                  ? const AscendEmptyState(
                      icon: Icons.chat_bubble_outline,
                      title: 'Say hello',
                      message: 'Your messages will show up here.',
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AscendSpacing.md),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        return _MessageBubble(
                          message: message,
                          isMine: message.senderId == myUserId,
                          onReport: message.senderId == myUserId
                              ? null
                              : () => _showReportDialog(
                                  context,
                                  controller,
                                  message.id,
                                ),
                        );
                      },
                    ),
            ),
            if (!isDeclined && !isPendingRequestToMe)
              _Composer(
                controller: _bodyController,
                isSending: state.isSending,
                onSend: () async {
                  final text = _bodyController.text;
                  final sent = await controller.sendMessage(text);
                  if (sent) _bodyController.clear();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReportDialog(
    BuildContext context,
    ConversationDetailController controller,
    String messageId,
  ) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report message'),
        content: AscendTextField(
          label: 'Reason',
          controller: reasonController,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Report'),
          ),
        ],
      ),
    );
    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      await controller.reportMessage(messageId, reasonController.text.trim());
    }
    reasonController.dispose();
  }
}

class _RequestBanner extends StatelessWidget {
  const _RequestBanner({required this.onAccept, required this.onDecline});

  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(AscendSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This is a message request.'),
          const SizedBox(height: AscendSpacing.sm),
          Row(
            children: [
              TextButton(onPressed: onDecline, child: const Text('Decline')),
              const SizedBox(width: AscendSpacing.sm),
              FilledButton(onPressed: onAccept, child: const Text('Accept')),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(AscendSpacing.md),
      child: Text(message, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    this.onReport,
  });

  final DirectMessage message;
  final bool isMine;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(
        horizontal: AscendSpacing.sm,
        vertical: AscendSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isMine
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message.body ?? '[Unsupported message]'),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (onReport != null)
            GestureDetector(onLongPress: onReport, child: bubble)
          else
            bubble,
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AscendSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: AscendTextField(label: 'Message', controller: controller),
          ),
          const SizedBox(width: AscendSpacing.sm),
          IconButton.filled(
            onPressed: isSending ? null : onSend,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
