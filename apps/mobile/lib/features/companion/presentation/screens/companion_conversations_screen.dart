import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../profile/domain/preferences_model.dart' show Companion;
import '../../domain/companion_conversation.dart';
import '../providers/companion_conversations_controller.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime date) {
  return '${_months[date.month - 1]} ${date.day}, ${date.year}';
}

/// "Conversation history" (Build Session 12 Part 8), reachable from the
/// "Conversation history" toggle in dashboard_screen.dart — deliberately
/// separate from `CompanionMemoryScreen`: this is the actual chat
/// transcript, listable/openable/renamable/deletable, never a structured
/// fact list.
class CompanionConversationsScreen extends ConsumerWidget {
  const CompanionConversationsScreen({super.key});

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all conversation history?'),
        content: const Text(
          'Every saved conversation with Atlas and Nova will be deleted. This never '
          'affects what Atlas and Nova remember about you — see "Manage companion '
          'memory" for that. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear history'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(companionConversationsControllerProvider.notifier).clear();
    }
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    CompanionConversationSummary conversation,
  ) async {
    final controller = TextEditingController(
      text: conversation.title ?? conversation.lastMessagePreview ?? '',
    );
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename conversation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 200,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newTitle != null && newTitle.isNotEmpty) {
      await ref
          .read(companionConversationsControllerProvider.notifier)
          .rename(conversation.id, newTitle);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CompanionConversationSummary conversation,
  ) async {
    await ref
        .read(companionConversationsControllerProvider.notifier)
        .delete(conversation.id);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Conversation deleted.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companionConversationsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Conversation history')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref
              .read(companionConversationsControllerProvider.notifier)
              .refresh(),
          child: ListView(
            padding: const EdgeInsets.all(AscendSpacing.md),
            children: [
              Text(
                'Your saved conversations with Atlas and Nova. Deleting a conversation '
                'never affects what Atlas and Nova remember about you.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AscendSpacing.md),
              if (state.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (state.conversations.isEmpty)
                const AscendEmptyState(
                  icon: Icons.forum_outlined,
                  title: 'No saved conversations yet',
                  message: 'Chats with Atlas or Nova will show up here.',
                )
              else ...[
                for (final conversation in state.conversations)
                  Card(
                    margin: const EdgeInsets.only(bottom: AscendSpacing.sm),
                    child: ListTile(
                      title: Text(
                        conversation.title ??
                            conversation.lastMessagePreview ??
                            'Conversation',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${conversation.companion == Companion.atlas ? 'Atlas' : 'Nova'} '
                        '· ${_formatDate(conversation.updatedAt)}',
                      ),
                      onTap: () => context.push(
                        RoutePaths.companionConversationDetailPath(
                          conversation.id,
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) {
                          if (action == 'rename') {
                            _rename(context, ref, conversation);
                          } else if (action == 'delete') {
                            _delete(context, ref, conversation);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'rename', child: Text('Rename')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AscendSpacing.md),
                OutlinedButton(
                  onPressed: () => _confirmClear(context, ref),
                  child: const Text('Clear all conversation history'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
