import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../providers/blocked_accounts_controller.dart';

/// "Blocked accounts" (Build Session 12 Part 12-14 — Privacy Center) — a
/// list of every account the caller has blocked, with an unblock action.
/// Reachable from the Privacy Center; previously the only way to unblock
/// someone was to revisit the exact profile screen used to block them.
class BlockedAccountsScreen extends ConsumerWidget {
  const BlockedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(blockedAccountsControllerProvider);
    final controller = ref.read(blockedAccountsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked accounts')),
      body: SafeArea(
        child: state.isLoading
            ? const AscendLoadingIndicator()
            : RefreshIndicator(
                onRefresh: controller.refresh,
                child: state.blocked.isEmpty
                    ? ListView(
                        children: const [
                          AscendEmptyState(
                            icon: Icons.block_outlined,
                            title: 'No blocked accounts',
                            message:
                                "Accounts you've blocked will show up here.",
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.all(AscendSpacing.md),
                        children: [
                          for (final blocked in state.blocked)
                            ListTile(
                              leading: CircleAvatar(
                                backgroundImage: blocked.avatarUrl != null
                                    ? NetworkImage(blocked.avatarUrl!)
                                    : null,
                                child: blocked.avatarUrl == null
                                    ? const Icon(Icons.person_outline)
                                    : null,
                              ),
                              title: Text(
                                blocked.displayName ?? 'Ascend member',
                              ),
                              trailing: TextButton(
                                onPressed: () =>
                                    controller.unblock(blocked.userId),
                                child: const Text('Unblock'),
                              ),
                            ),
                        ],
                      ),
              ),
      ),
    );
  }
}
