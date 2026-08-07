import 'package:mobile/core/entitlements/capability.dart';
import 'package:mobile/core/entitlements/subscription_status_repository.dart';

/// In-memory stand-in for [SubscriptionStatusRepository] — defaults to
/// [PlanTier.free], matching "no billing exists yet" for every widget
/// test that doesn't care about tier.
class FakeSubscriptionStatusRepository implements SubscriptionStatusRepository {
  FakeSubscriptionStatusRepository({this.tier = PlanTier.free});

  PlanTier tier;

  @override
  Future<PlanTier> getMyTier() async => tier;
}
