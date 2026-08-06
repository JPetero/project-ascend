import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'capability.dart';

/// No billing exists yet this session (see
/// packages/docs/product/parking-lot.md), so every account resolves to
/// [PlanTier.free]. Real per-user tier resolution ships alongside
/// subscriptions/payment processing — this provider is the single place
/// that will change when it does.
final planTierProvider = Provider<PlanTier>((ref) => PlanTier.free);

final capabilityProvider = Provider.family<bool, AppCapability>((
  ref,
  capability,
) {
  final tier = ref.watch(planTierProvider);
  return hasCapability(tier, capability);
});
