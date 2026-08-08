import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/core_providers.dart';
import 'capability.dart';
import 'subscription_status_repository.dart';

final subscriptionStatusRepositoryProvider =
    Provider<SubscriptionStatusRepository>((ref) {
      return SubscriptionStatusRepository(
        apiClient: ref.watch(apiClientProvider),
      );
    });

/// The caller's real per-user tier (Founder Scenario 27's subscription
/// foundation) — a genuine `/subscriptions/me` round trip, not a
/// hardcoded literal. No billing exists yet (see
/// packages/docs/product/parking-lot.md), so this still resolves to
/// [PlanTier.free] for every account in practice; the fetch failing for
/// any reason (offline, unauthenticated, a server error) also falls back
/// to [PlanTier.free] — this must never fail open into Premium. Public
/// (not a leading-underscore private) so a test can `await
/// container.read(fetchedPlanTierProvider.future)` to deterministically
/// wait for it to settle instead of polling [planTierProvider] on a
/// timer — see ai_provider_routing_test.dart.
final fetchedPlanTierProvider = FutureProvider<PlanTier>((ref) async {
  final repository = ref.watch(subscriptionStatusRepositoryProvider);
  return repository.getMyTier();
});

final planTierProvider = Provider<PlanTier>((ref) {
  return ref.watch(fetchedPlanTierProvider).valueOrNull ?? PlanTier.free;
});

final capabilityProvider = Provider.family<bool, AppCapability>((
  ref,
  capability,
) {
  final tier = ref.watch(planTierProvider);
  return hasCapability(tier, capability);
});
