import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/promote/domain/campaign.dart';
import 'package:mobile/features/promote/presentation/providers/campaign_detail_controller.dart';

import '../../helpers/fake_promote_repository.dart';

void main() {
  test('loads metrics for the campaign', () async {
    final repository = FakePromoteRepository(
      campaigns: [sampleCampaign(id: 'campaign-1')],
    );
    repository.metricsByCampaign['campaign-1'] = const CampaignMetrics(
      status: CampaignStatus.active,
      organicLikes: 3,
      organicComments: 1,
      promotedImpressions: 10,
      promotedClicks: 2,
    );
    final controller = CampaignDetailController(
      repository: repository,
      campaignId: 'campaign-1',
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.metrics?.organicLikes, 3);
    expect(controller.state.metrics?.promotedImpressions, 10);
  });

  test('organic and promoted metrics stay separate, never summed', () async {
    final repository = FakePromoteRepository(
      campaigns: [sampleCampaign(id: 'campaign-1')],
    );
    repository.metricsByCampaign['campaign-1'] = const CampaignMetrics(
      status: CampaignStatus.active,
      organicLikes: 5,
      organicComments: 5,
      promotedImpressions: 0,
      promotedClicks: 0,
    );
    final controller = CampaignDetailController(
      repository: repository,
      campaignId: 'campaign-1',
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.metrics?.organicLikes, 5);
    expect(controller.state.metrics?.promotedImpressions, 0);
    expect(controller.state.metrics?.promotedClicks, 0);
  });

  test('ending a campaign reloads metrics with the new status', () async {
    final repository = FakePromoteRepository(
      campaigns: [sampleCampaign(id: 'campaign-1')],
    );
    final controller = CampaignDetailController(
      repository: repository,
      campaignId: 'campaign-1',
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final ok = await controller.end();

    expect(ok, isTrue);
    expect(controller.state.metrics?.status, CampaignStatus.ended);
    expect(controller.state.isEnding, isFalse);
  });

  test('a missing campaign surfaces an error instead of crashing', () async {
    final repository = FakePromoteRepository();
    final controller = CampaignDetailController(
      repository: repository,
      campaignId: 'does-not-exist',
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.metrics, isNull);
    expect(controller.state.error, isNotNull);
  });
}
