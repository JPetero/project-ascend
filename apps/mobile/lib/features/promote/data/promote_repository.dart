import '../../../core/networking/api_client.dart';
import '../domain/campaign.dart';

/// Thin client for services/api/src/modules/promote — Founder Scenario
/// 23's transparent-promotion architecture. Creating a campaign
/// requires Premium (`AppCapability.ascendPromote`); no live billing
/// exists this session.
class PromoteRepository {
  PromoteRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Campaign> createCampaign({
    required String postId,
    required num budgetAmount,
    required String budgetCurrency,
  }) async {
    final envelope = await _apiClient.post(
      '/promote/campaigns',
      (data) => data as Map<String, dynamic>,
      data: {
        'postId': postId,
        'budgetAmount': budgetAmount,
        'budgetCurrency': budgetCurrency,
      },
    );
    return Campaign.fromJson(envelope.data!);
  }

  Future<List<Campaign>> listMine() async {
    final envelope = await _apiClient.get(
      '/promote/campaigns',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map((c) => Campaign.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<CampaignMetrics> getMetrics(String id) async {
    final envelope = await _apiClient.get(
      '/promote/campaigns/$id/metrics',
      (data) => data as Map<String, dynamic>,
    );
    return CampaignMetrics.fromJson(envelope.data!);
  }

  Future<void> endCampaign(String id) async {
    await _apiClient.delete('/promote/campaigns/$id', (_) => null);
  }
}
