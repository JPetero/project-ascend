import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entitlements/capability.dart';
import '../../../../core/entitlements/capability_provider.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../feature_flags/domain/ascend_feature.dart';
import '../../../feature_flags/presentation/providers/feature_flags_provider.dart';
import '../../domain/campaign.dart';
import '../providers/promote_controller.dart';

/// Ascend Promote — Founder Scenario 23. Creating a campaign requires
/// Premium; viewing/interacting with promoted content elsewhere in the
/// app stays free for everyone. Every campaign starts PENDING_REVIEW
/// and only an admin can move it to ACTIVE — nothing here can ever
/// serve paid reach without moderation review first. The ASCEND_PROMOTE
/// feature flag (Build Session 13 continuation Part A, default closed)
/// additionally gates only the "new campaign" action, not this screen's
/// existing-campaign list — organic Community browsing/interaction is
/// never affected by this flag either way.
class PromoteScreen extends ConsumerWidget {
  const PromoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = ref.watch(
      capabilityProvider(AppCapability.ascendPromote),
    );
    final canCreate =
        hasAccess &&
        ref.watch(featureEnabledProvider(AscendFeature.ascendPromote));

    return Scaffold(
      appBar: AppBar(title: const Text('Ascend Promote')),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => context.push(RoutePaths.promoteCampaignCreate),
              tooltip: 'New campaign',
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        child: hasAccess
            ? const _CampaignList()
            : const Center(
                child: AscendEmptyState(
                  icon: Icons.lock_outline,
                  title: 'Ascend Promote is a Premium creator tool',
                  message:
                      'Paying to promote a post unlocks with Premium. Viewing and interacting '
                      'with promoted content anywhere in the app always stays free — nothing '
                      'here is simulated.',
                ),
              ),
      ),
    );
  }
}

class _CampaignList extends ConsumerWidget {
  const _CampaignList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(promoteControllerProvider);
    final controller = ref.read(promoteControllerProvider.notifier);

    if (state.isLoading) {
      return const AscendLoadingIndicator();
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: state.campaigns.isEmpty
          ? ListView(
              children: const [
                AscendEmptyState(
                  icon: Icons.campaign_outlined,
                  title: 'No campaigns yet',
                  message:
                      'Promote one of your own posts to reach more people — every campaign is '
                      'reviewed before it goes live, and paid reach is always labeled Promoted.',
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(AscendSpacing.md),
              children: [
                for (final campaign in state.campaigns)
                  AscendCard(
                    onTap: () => context.push(
                      RoutePaths.promoteCampaignDetailPath(campaign.id),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${campaign.budgetAmount} ${campaign.budgetCurrency} budget',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                campaignStatusLabel(campaign.status),
                                style: Theme.of(context).textTheme.bodySmall,
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
    );
  }
}
