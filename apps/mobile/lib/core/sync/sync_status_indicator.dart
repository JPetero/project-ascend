import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/design_system.dart';
import 'sync_providers.dart';

/// A small, generic "your changes are safe, here's where sync stands"
/// banner. Renders nothing when there's no outstanding work, so it's safe
/// to drop into any screen (workout summary today, meal log tomorrow)
/// without adding visual noise for the common case.
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    if (!status.hasWork) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final String label;
    final IconData icon;
    if (status.isSyncing) {
      label = 'Syncing…';
      icon = Icons.sync;
    } else if (status.failedCount > 0) {
      label = status.failedCount == 1
          ? '1 change needs attention'
          : '${status.failedCount} changes need attention';
      icon = Icons.sync_problem_outlined;
    } else {
      label = status.pendingCount == 1
          ? '1 change waiting to sync'
          : '${status.pendingCount} changes waiting to sync';
      icon = Icons.cloud_upload_outlined;
    }

    return Semantics(
      label: label,
      child: AscendCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AscendSpacing.md,
          vertical: AscendSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AscendSpacing.sm),
            Expanded(
              child: Text(label, style: theme.textTheme.bodyMedium),
            ),
            if (status.failedCount > 0 && !status.isSyncing)
              TextButton(
                onPressed: () => ref.read(syncEngineProvider).retryAllFailed(),
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
