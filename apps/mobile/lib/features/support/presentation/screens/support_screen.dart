import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/support_ticket.dart';
import '../providers/support_controller.dart';

/// Help center — Founder Scenario 27. Every category (help, bug
/// report, safety report, accessibility feedback, account recovery,
/// billing help, moderation appeal) is free on every tier; nothing
/// here is ever Premium-gated.
class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(supportControllerProvider);
    final controller = ref.read(supportControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Help & support')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RoutePaths.supportTicketCreate),
        tooltip: 'New ticket',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AscendSpacing.md,
                AscendSpacing.md,
                AscendSpacing.md,
                0,
              ),
              child: AscendCard(
                onTap: () => context.push(RoutePaths.helpCenter),
                child: Row(
                  children: [
                    const Icon(Icons.help_outline),
                    const SizedBox(width: AscendSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Help Center',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            'Browse answers before filing a ticket',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            Expanded(
              child: state.isLoading
                  ? const AscendLoadingIndicator()
                  : RefreshIndicator(
                      onRefresh: controller.refresh,
                      child: state.tickets.isEmpty
                          ? ListView(
                              children: const [
                                AscendEmptyState(
                                  icon: Icons.support_agent_outlined,
                                  title: 'No support tickets yet',
                                  message:
                                      'Need help, want to report a bug or safety concern, or have a '
                                      'billing question? Start a ticket — it is always free.',
                                ),
                              ],
                            )
                          : ListView(
                              padding: const EdgeInsets.all(AscendSpacing.md),
                              children: [
                                for (final ticket in state.tickets)
                                  AscendCard(
                                    onTap: () => context.push(
                                      RoutePaths.supportTicketDetailPath(
                                        ticket.id,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ticket.subject,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleSmall,
                                              ),
                                              Text(
                                                '${supportCategoryLabel(ticket.category)} · '
                                                '${supportTicketStatusLabel(ticket.status)}',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
