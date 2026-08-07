import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/campaign.dart';
import '../providers/campaign_detail_controller.dart';

class CampaignDetailScreen extends ConsumerWidget {
  const CampaignDetailScreen({super.key, required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(campaignDetailControllerProvider(campaignId));
    final controller = ref.read(
      campaignDetailControllerProvider(campaignId).notifier,
    );

    if (state.isLoading) {
      return const Scaffold(body: SafeArea(child: AscendLoadingIndicator()));
    }
    final metrics = state.metrics;
    if (metrics == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Campaign')),
        body: SafeArea(
          child: AscendEmptyState(
            icon: Icons.error_outline,
            title: "Couldn't load this campaign",
            message: state.error ?? 'It may have been removed.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Campaign')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(AscendSpacing.md),
            children: [
              AscendCard(
                child: Row(
                  children: [
                    const Icon(Icons.campaign_outlined),
                    const SizedBox(width: AscendSpacing.sm),
                    Text(
                      campaignStatusLabel(metrics.status),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AscendSpacing.lg),
              Text('Organic', style: Theme.of(context).textTheme.titleSmall),
              const Text(
                'Free, unpaid engagement — never blended with paid reach below.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: AscendSpacing.sm),
              AscendCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetricColumn(label: 'Likes', value: metrics.organicLikes),
                    _MetricColumn(
                      label: 'Comments',
                      value: metrics.organicComments,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AscendSpacing.lg),
              Text(
                'Promoted (paid)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Text(
                'Never guaranteed, and has zero influence on Rankings.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: AscendSpacing.sm),
              AscendCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetricColumn(
                      label: 'Impressions',
                      value: metrics.promotedImpressions,
                    ),
                    _MetricColumn(
                      label: 'Clicks',
                      value: metrics.promotedClicks,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AscendSpacing.lg),
              if (metrics.status == CampaignStatus.active ||
                  metrics.status == CampaignStatus.pendingReview)
                AscendSecondaryButton(
                  label: 'End campaign',
                  isLoading: state.isEnding,
                  onPressed: state.isEnding
                      ? null
                      : () async {
                          final ok = await controller.end();
                          if (!context.mounted) return;
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Couldn't end the campaign — try again.",
                                ),
                              ),
                            );
                          }
                        },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
