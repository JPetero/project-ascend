import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../profile/presentation/providers/preferences_controller.dart';

/// Privacy Center (Build Session 12 Part 12-14) — a single place that
/// gathers every privacy-relevant control already scattered across the
/// app (companion memory, conversation history, blocked accounts,
/// gallery visibility, data export, account & security) rather than a
/// new privacy subsystem. Every toggle here writes the exact same
/// backend field its original scattered control does — this is a
/// discoverability layer, not a second source of truth.
class PrivacyCenterScreen extends ConsumerWidget {
  const PrivacyCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(
      preferencesControllerProvider.select((s) => s.asData?.value),
    );
    final controller = ref.read(preferencesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Center')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          children: [
            Text(
              'Ascend & Atlas/Nova',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AscendSpacing.sm),
            AscendCard(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('AI memory'),
                    subtitle: const Text(
                      'Let Ascend remember context between conversations.',
                    ),
                    value: preferences?.aiMemoryEnabled ?? false,
                    onChanged: (value) =>
                        controller.update({'aiMemoryEnabled': value}),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Manage companion memory'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(RoutePaths.companionMemory),
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Conversation history'),
                    subtitle: const Text(
                      'Save your chat with Atlas and Nova so you can reopen it later.',
                    ),
                    value: preferences?.conversationHistoryEnabled ?? true,
                    onChanged: (value) => controller.update({
                      'conversationHistoryEnabled': value,
                    }),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Manage conversation history'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        context.push(RoutePaths.companionConversations),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AscendSpacing.lg),
            Text('Community', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AscendSpacing.sm),
            AscendCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.block_outlined),
                title: const Text('Blocked accounts'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RoutePaths.blockedAccounts),
              ),
            ),
            const SizedBox(height: AscendSpacing.lg),
            Text('Your data', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AscendSpacing.sm),
            AscendCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text('Gallery visibility'),
                    subtitle: const Text('Choose which photos are private.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(RoutePaths.gallery),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.file_download_outlined),
                    title: const Text('Export my data'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(RoutePaths.dataExport),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.shield_outlined),
                    title: const Text('Account & Security'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(RoutePaths.accountSecurity),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
