import 'package:mobile/features/promote/data/promote_repository.dart';
import 'package:mobile/features/promote/domain/campaign.dart';

Campaign sampleCampaign({
  String id = 'campaign-1',
  String postId = 'post-1',
  CampaignStatus status = CampaignStatus.pendingReview,
  num budgetAmount = 50,
  String budgetCurrency = 'USD',
}) {
  return Campaign(
    id: id,
    postId: postId,
    status: status,
    budgetAmount: budgetAmount,
    budgetCurrency: budgetCurrency,
    createdAt: DateTime.utc(2026, 8, 7),
  );
}

/// In-memory stand-in for [PromoteRepository].
class FakePromoteRepository implements PromoteRepository {
  FakePromoteRepository({List<Campaign>? campaigns})
    : campaigns = campaigns ?? [];

  final List<Campaign> campaigns;
  final Map<String, CampaignMetrics> metricsByCampaign = {};

  @override
  Future<Campaign> createCampaign({
    required String postId,
    required num budgetAmount,
    required String budgetCurrency,
  }) async {
    final campaign = Campaign(
      id: 'campaign-${campaigns.length}',
      postId: postId,
      status: CampaignStatus.pendingReview,
      budgetAmount: budgetAmount,
      budgetCurrency: budgetCurrency,
      createdAt: DateTime.now(),
    );
    campaigns.insert(0, campaign);
    return campaign;
  }

  @override
  Future<List<Campaign>> listMine() async => List.unmodifiable(campaigns);

  @override
  Future<CampaignMetrics> getMetrics(String id) async {
    final metrics = metricsByCampaign[id];
    if (metrics != null) return metrics;
    final campaign = campaigns.firstWhere(
      (c) => c.id == id,
      orElse: () => throw Exception('not found'),
    );
    return CampaignMetrics(
      status: campaign.status,
      organicLikes: 0,
      organicComments: 0,
      promotedImpressions: 0,
      promotedClicks: 0,
    );
  }

  @override
  Future<void> endCampaign(String id) async {
    final index = campaigns.indexWhere((c) => c.id == id);
    if (index == -1) throw Exception('not found');
    final campaign = campaigns[index];
    campaigns[index] = Campaign(
      id: campaign.id,
      postId: campaign.postId,
      status: CampaignStatus.ended,
      budgetAmount: campaign.budgetAmount,
      budgetCurrency: campaign.budgetCurrency,
      createdAt: campaign.createdAt,
    );
  }
}
