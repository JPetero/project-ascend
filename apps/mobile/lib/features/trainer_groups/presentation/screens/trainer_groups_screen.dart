import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/trainer_group.dart';
import '../providers/trainer_groups_controller.dart';

/// The Trainer Groups home — the caller's groups plus any pending
/// invitations, reachable from the Community tab. Free tier: one owned
/// group, a small member limit — see
/// packages/docs/product/user-scenario-bible.md Scenario 24.
class TrainerGroupsScreen extends ConsumerWidget {
  const TrainerGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trainerGroupsControllerProvider);
    final controller = ref.read(trainerGroupsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainer Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_outlined),
            tooltip: 'Trainer dashboard',
            onPressed: () => context.push(RoutePaths.trainerDashboard),
          ),
        ],
      ),
      floatingActionButton: state.groups.any((g) => g.isOwnGroup)
          ? null
          : FloatingActionButton(
              onPressed: () => context.push(RoutePaths.trainerGroupCreate),
              tooltip: 'New group',
              child: const Icon(Icons.add),
            ),
      body: SafeArea(
        child: state.isLoading
            ? const AscendLoadingIndicator()
            : RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView(
                  padding: const EdgeInsets.all(AscendSpacing.md),
                  children: [
                    if (state.invitations.isNotEmpty) ...[
                      Text(
                        'Invitations',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AscendSpacing.sm),
                      for (final invitation in state.invitations)
                        _InvitationCard(
                          invitation: invitation,
                          onAccept: () async {
                            final ok = await controller.acceptInvitation(
                              invitation.id,
                            );
                            if (!context.mounted) return;
                            if (ok) {
                              context.push(
                                RoutePaths.trainerGroupDetailPath(
                                  invitation.groupId,
                                ),
                              );
                            }
                          },
                          onDecline: () =>
                              controller.declineInvitation(invitation.id),
                        ),
                      const SizedBox(height: AscendSpacing.lg),
                    ],
                    Text(
                      'Your groups',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AscendSpacing.sm),
                    if (state.groups.isEmpty)
                      const AscendEmptyState(
                        icon: Icons.groups_2_outlined,
                        title: 'No groups yet',
                        message:
                            'Create a free group to train with friends or clients — chat, share plans, '
                            'and invite people in.',
                      )
                    else
                      for (final group in state.groups)
                        AscendCard(
                          onTap: () => context.push(
                            RoutePaths.trainerGroupDetailPath(group.id),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    Text(
                                      '${group.members.length}/${group.memberLimit} members'
                                      '${group.isOwnGroup ? ' · You own this group' : ''}',
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
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    required this.onAccept,
    required this.onDecline,
  });

  final TrainerGroupInvitation invitation;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return AscendCard(
      child: Row(
        children: [
          const Expanded(child: Text("You've been invited to join a group")),
          TextButton(onPressed: onDecline, child: const Text('Decline')),
          FilledButton(onPressed: onAccept, child: const Text('Accept')),
        ],
      ),
    );
  }
}
