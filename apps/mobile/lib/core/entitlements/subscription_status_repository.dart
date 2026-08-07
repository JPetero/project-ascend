import '../networking/api_client.dart';
import 'capability.dart';

/// The minimal read [capability_provider.dart] needs — just the caller's
/// current [PlanTier] — kept separate from the richer
/// `features/subscriptions/data/subscriptions_repository.dart` (pricing,
/// eligibility) so this core layer never has to import a feature.
class SubscriptionStatusRepository {
  SubscriptionStatusRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<PlanTier> getMyTier() async {
    final envelope = await _apiClient.get(
      '/subscriptions/me',
      (data) => data as Map<String, dynamic>,
    );
    return (envelope.data!['tier'] as String) == 'PREMIUM'
        ? PlanTier.premium
        : PlanTier.free;
  }
}
