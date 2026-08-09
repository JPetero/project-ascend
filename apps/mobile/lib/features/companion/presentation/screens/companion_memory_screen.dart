import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/companion_memory_note.dart';
import '../providers/companion_memory_controller.dart';

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

/// What Atlas/Nova remembers about the user across conversations (Build
/// Session 10 Part 15), reachable from the "AI memory" toggle in
/// dashboard_screen.dart. Build Session 11 Part 4: each remembered fact
/// is now a structured, categorized entry (never raw free-form text —
/// see `MemoryExtractionService`'s doc comment server-side) with its own
/// creation date and a per-entry delete, not just clear-everything.
class CompanionMemoryScreen extends ConsumerWidget {
  const CompanionMemoryScreen({super.key});

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear companion memory?'),
        content: const Text(
          'Atlas and Nova will forget everything remembered from past conversations. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear memory'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(companionMemoryControllerProvider.notifier).clear();
    }
  }

  Future<void> _deleteNote(
    BuildContext context,
    WidgetRef ref,
    CompanionMemoryNote note,
  ) async {
    await ref
        .read(companionMemoryControllerProvider.notifier)
        .deleteNote(note.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Forgotten.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companionMemoryControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Companion memory')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(companionMemoryControllerProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(AscendSpacing.md),
            children: [
              Text(
                'What Atlas and Nova remember from past conversations — a short list of '
                'preferences, never a full transcript, and never anything sensitive '
                'like symptoms or emotional disclosures.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AscendSpacing.md),
              if (state.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (state.notes.isEmpty)
                const AscendEmptyState(
                  icon: Icons.psychology_outlined,
                  title: 'Nothing remembered yet',
                  message:
                      'As you chat with Atlas or Nova, preferences worth remembering show up here.',
                )
              else ...[
                for (final note in state.notes)
                  Card(
                    margin: const EdgeInsets.only(bottom: AscendSpacing.sm),
                    child: ListTile(
                      title: Text(note.value),
                      subtitle: Text(
                        '${note.category.label} · Remembered ${_formatDate(note.createdAt)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Forget this',
                        onPressed: () => _deleteNote(context, ref, note),
                      ),
                    ),
                  ),
                const SizedBox(height: AscendSpacing.md),
                OutlinedButton(
                  onPressed: () => _confirmClear(context, ref),
                  child: const Text('Clear all memory'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
