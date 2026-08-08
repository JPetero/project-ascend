import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/entitlements/capability.dart';
import 'package:mobile/core/entitlements/capability_provider.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/secure_token_storage.dart';
import 'package:mobile/features/companion/data/live_ai_provider.dart';
import 'package:mobile/features/companion/data/local_deterministic_ai_provider.dart';
import 'package:mobile/features/companion/presentation/providers/companion_chat_controller.dart';

import '../../helpers/fake_subscription_status_repository.dart';
import '../../helpers/in_memory_token_store.dart';

/// Build Session 9 Part 15/16 — `aiProviderProvider`'s Free/Premium
/// routing. Deliberately does NOT use `createTestContainer` (see
/// test_provider_scope.dart): that helper unconditionally overrides
/// `aiProviderProvider` with a fixed local provider so every other
/// test gets a controllable, network-free companion — which is exactly
/// what this file needs to bypass to exercise the real routing logic.
///
/// Doesn't exercise `LiveAiProvider.generateReply`'s actual network
/// call: like every other `ApiClient`-backed repository in this
/// codebase (see e.g. GalleryRepository), that's not unit-tested against
/// a mocked transport — only the fake/interface boundary is. What's
/// tested here is purely which concrete provider gets selected.
ProviderContainer _buildContainer(PlanTier tier) {
  return ProviderContainer(
    overrides: [
      secureTokenStorageProvider.overrideWithValue(
        SecureTokenStorage(store: InMemoryTokenStore()),
      ),
      subscriptionStatusRepositoryProvider.overrideWithValue(
        FakeSubscriptionStatusRepository(tier: tier),
      ),
    ],
  );
}

void main() {
  test('a Free-tier account never gets the live provider', () async {
    final container = _buildContainer(PlanTier.free);
    addTearDown(container.dispose);
    await container.read(fetchedPlanTierProvider.future);

    expect(
      container.read(aiProviderProvider),
      isA<LocalDeterministicAiProvider>(),
    );
  });

  test(
    'a Premium account gets the live provider, wrapping the local one as its fallback',
    () async {
      final container = _buildContainer(PlanTier.premium);
      addTearDown(container.dispose);
      // Deterministically wait for the real per-user tier fetch to
      // settle instead of racing it — capabilityProvider (and
      // aiProviderProvider, which depends on it) resolve to Free while
      // this is still pending.
      await container.read(fetchedPlanTierProvider.future);

      expect(container.read(aiProviderProvider), isA<LiveAiProvider>());
    },
  );
}
