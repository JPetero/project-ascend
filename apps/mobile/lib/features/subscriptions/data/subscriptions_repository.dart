import '../../../core/networking/api_client.dart';
import '../domain/subscription_status.dart';

/// Thin client for services/api/src/modules/subscriptions — centralized
/// pricing, the caller's tier, and the affordability-program
/// application pipeline (Founder Scenario 27). There is deliberately no
/// self-service "upgrade" call here — no billing integration exists
/// this session.
class SubscriptionsRepository {
  SubscriptionsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<PricingPoint>> getPricing() async {
    final envelope = await _apiClient.get(
      '/subscriptions/pricing',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map((p) => PricingPoint.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<SubscriptionStatus> getMyStatus() async {
    final envelope = await _apiClient.get(
      '/subscriptions/me',
      (data) => data as Map<String, dynamic>,
    );
    return SubscriptionStatus.fromJson(envelope.data!);
  }

  Future<EligibilityStatus> applyForEligibility({
    required AffordabilityProgram program,
    String? notes,
  }) async {
    final envelope = await _apiClient.post(
      '/subscriptions/eligibility',
      (data) => data as Map<String, dynamic>,
      data: {'program': affordabilityProgramToJson(program), 'notes': ?notes},
    );
    return EligibilityStatus.fromJson(envelope.data!);
  }
}
