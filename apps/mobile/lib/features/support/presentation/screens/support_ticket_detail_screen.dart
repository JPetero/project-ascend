import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/support_ticket.dart';
import '../providers/support_ticket_detail_controller.dart';

class SupportTicketDetailScreen extends ConsumerStatefulWidget {
  const SupportTicketDetailScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState
    extends ConsumerState<SupportTicketDetailScreen> {
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      supportTicketDetailControllerProvider(widget.ticketId),
    );
    final controller = ref.read(
      supportTicketDetailControllerProvider(widget.ticketId).notifier,
    );

    if (state.isLoading) {
      return const Scaffold(body: SafeArea(child: AscendLoadingIndicator()));
    }
    final ticket = state.ticket;
    if (ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ticket')),
        body: SafeArea(
          child: AscendEmptyState(
            icon: Icons.error_outline,
            title: "Couldn't load this ticket",
            message: state.error ?? 'It may have been removed.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(ticket.subject)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AscendSpacing.md),
              child: AscendCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${supportCategoryLabel(ticket.category)} · '
                      '${supportTicketStatusLabel(ticket.status)}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AscendSpacing.sm),
                    Text(ticket.message),
                  ],
                ),
              ),
            ),
            Expanded(
              child: (ticket.replies == null || ticket.replies!.isEmpty)
                  ? const AscendEmptyState(
                      icon: Icons.forum_outlined,
                      title: 'No replies yet',
                      message: "We'll respond here as soon as we can.",
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AscendSpacing.md,
                      ),
                      children: [
                        for (final reply in ticket.replies!)
                          Align(
                            alignment: reply.isStaff
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: AscendSpacing.xs,
                              ),
                              padding: const EdgeInsets.all(AscendSpacing.sm),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: reply.isStaff
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest
                                    : Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(
                                  AscendRadius.medium,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (reply.isStaff)
                                    Text(
                                      'Ascend Support',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
                                    ),
                                  Text(reply.body),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AscendSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      decoration: const InputDecoration(
                        hintText: 'Add a reply…',
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendReply(controller),
                    ),
                  ),
                  IconButton(
                    icon: state.isReplying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed: state.isReplying
                        ? null
                        : () => _sendReply(controller),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendReply(SupportTicketDetailController controller) async {
    final body = _replyController.text.trim();
    if (body.isEmpty) return;
    _replyController.clear();
    final sent = await controller.addReply(body);
    if (!sent) _replyController.text = body;
  }
}
