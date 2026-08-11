import 'package:mobile/core/entitlements/capability.dart';
import 'package:mobile/features/subscriptions/data/subscriptions_repository.dart';
import 'package:mobile/features/subscriptions/domain/subscription_status.dart';

/// In-memory stand-in for [SubscriptionsRepository].
class FakeSubscriptionsRepository implements SubscriptionsRepository {
  FakeSubscriptionsRepository({
    List<PricingPoint>? pricing,
    SubscriptionStatus? status,
    this.shouldFail = false,
  }) : pricing =
           pricing ??
           const [
             PricingPoint(
               currency: 'USD',
               standardAmount: 12.99,
               eligibleAmount: 7.99,
             ),
             PricingPoint(
               currency: 'PHP',
               standardAmount: 599,
               eligibleAmount: 299,
             ),
           ],
       status = status ?? const SubscriptionStatus(tier: PlanTier.free);

  final List<PricingPoint> pricing;
  SubscriptionStatus status;
  bool shouldFail;

  @override
  Future<List<PricingPoint>> getPricing() async {
    if (shouldFail) throw Exception('Network error');
    return pricing;
  }

  @override
  Future<SubscriptionStatus> getMyStatus() async {
    if (shouldFail) throw Exception('Network error');
    return status;
  }

  @override
  Future<EligibilityStatus> applyForEligibility({
    required AffordabilityProgram program,
    String? notes,
  }) async {
    final eligibility = EligibilityStatus(
      program: program,
      status: AffordabilityStatus.pending,
    );
    status = SubscriptionStatus(tier: status.tier, eligibility: eligibility);
    return eligibility;
  }
}
