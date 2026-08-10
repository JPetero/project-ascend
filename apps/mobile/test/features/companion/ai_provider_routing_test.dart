import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/entitlements/capability.dart';
import 'package:mobile/core/entitlements/capability_provider.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/secure_token_storage.dart';
import 'package:mobile/features/companion/data/live_ai_provider.dart';
import 'package:mobile/features/companion/data/local_deterministic_ai_provider.dart';
import 'package:mobile/features/companion/presentation/providers/companion_chat_controller.dart';
import 'package:mobile/features/feature_flags/presentation/providers/feature_flags_provider.dart';

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
ProviderContainer _buildContainer(PlanTier tier, {bool liveAiEnabled = true}) {
  return ProviderContainer(
    overrides: [
      secureTokenStorageProvider.overrideWithValue(
        SecureTokenStorage(store: InMemoryTokenStore()),
      ),
      subscriptionStatusRepositoryProvider.overrideWithValue(
        FakeSubscriptionStatusRepository(tier: tier),
      ),
      // LIVE_AI defaults closed (Build Session 13 continuation Part A) —
      // these tests are about entitlement routing, not the flag itself,
      // so it's explicitly enabled here (see
      // feature_enabled_provider_test.dart for the flag's own outage/
      // missing/false behavior).
      featureFlagsProvider.overrideWith(
        (ref) async => {'LIVE_AI': liveAiEnabled},
      ),
    ],
  );
}

void main() {
  test('a Free-tier account never gets the live provider', () async {
    final container = _buildContainer(PlanTier.free);
    addTearDown(container.dispose);
    await container.read(fetchedPlanTierProvider.future);
    await container.read(featureFlagsProvider.future);

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
      await container.read(featureFlagsProvider.future);

      expect(container.read(aiProviderProvider), isA<LiveAiProvider>());
    },
  );

  test(
    'a Premium account still gets a LiveAiProvider when LIVE_AI is disabled, but with chat replies turned off',
    () async {
      // LIVE_AI disabled must not also silence Research Mode (see
      // companion_chat_controller.dart's aiProviderProvider doc comment),
      // so the provider selection itself is unaffected — only
      // LiveAiProvider.chatEnabled changes.
      final container = _buildContainer(PlanTier.premium, liveAiEnabled: false);
      addTearDown(container.dispose);
      await container.read(fetchedPlanTierProvider.future);
      await container.read(featureFlagsProvider.future);

      final provider = container.read(aiProviderProvider);
      expect(provider, isA<LiveAiProvider>());
      expect((provider as LiveAiProvider).chatEnabled, isFalse);
    },
  );
}
