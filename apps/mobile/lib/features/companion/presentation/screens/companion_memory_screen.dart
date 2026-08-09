import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../providers/companion_memory_controller.dart';

/// What Atlas/Nova remembers about the user across conversations (Build
/// Session 10 Part 15), reachable from the "AI memory" toggle in
/// dashboard_screen.dart. Every note shown here is the user's own past
/// words, stored verbatim server-side — never an invented summary — so
/// this screen never risks showing a fabricated "memory."
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
                "What Atlas and Nova remember from past conversations — in your own words, "
                'never invented.',
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
                      'As you chat with Atlas or Nova, anything worth remembering shows up here.',
                )
              else ...[
                for (final note in state.notes)
                  Card(
                    margin: const EdgeInsets.only(bottom: AscendSpacing.sm),
                    child: Padding(
                      padding: const EdgeInsets.all(AscendSpacing.md),
                      child: Text(note),
                    ),
                  ),
                const SizedBox(height: AscendSpacing.md),
                OutlinedButton(
                  onPressed: () => _confirmClear(context, ref),
                  child: const Text('Clear memory'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
