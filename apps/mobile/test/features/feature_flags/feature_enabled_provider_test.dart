import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/feature_flags/domain/ascend_feature.dart';
import 'package:mobile/features/feature_flags/presentation/providers/feature_flags_provider.dart';

import '../../helpers/fake_feature_flags_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

/// Build Session 13 Part 1 — featureEnabledProvider must never fail open
/// on a risky/external/Premium feature, and must never flicker off a
/// safe core feature, during an API outage.
void main() {
  Future<ProviderContainer> pumpedContainer(
    WidgetTester tester, {
    required FakeFeatureFlagsRepository repository,
  }) async {
    final container = await createTestContainer(
      signedIn: true,
      featureFlagsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, child) {
              ref.watch(featureFlagsProvider);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await pumpForAsyncSettle(tester);
    return container;
  }

  testWidgets(
    'during an API outage, a risky/external feature resolves to its closed registry default',
    (tester) async {
      final container = await pumpedContainer(
        tester,
        repository: FakeFeatureFlagsRepository(throwOnResolve: true),
      );

      expect(
        container.read(featureEnabledProvider(AscendFeature.liveAi)),
        isFalse,
      );
      expect(
        container.read(featureEnabledProvider(AscendFeature.researchMode)),
        isFalse,
      );
      expect(
        container.read(featureEnabledProvider(AscendFeature.storePurchases)),
        isFalse,
      );
      expect(
        container.read(featureEnabledProvider(AscendFeature.ascendPromote)),
        isFalse,
      );
      expect(
        container.read(featureEnabledProvider(AscendFeature.visionFormCoach)),
        isFalse,
      );
    },
  );

  testWidgets(
    'during an API outage, a safe core feature resolves to its open registry default',
    (tester) async {
      final container = await pumpedContainer(
        tester,
        repository: FakeFeatureFlagsRepository(throwOnResolve: true),
      );

      expect(
        container.read(featureEnabledProvider(AscendFeature.trainerDashboard)),
        isTrue,
      );
      expect(
        container.read(
          featureEnabledProvider(AscendFeature.trainerVerification),
        ),
        isTrue,
      );
      expect(
        container.read(featureEnabledProvider(AscendFeature.remotePush)),
        isTrue,
      );
      expect(
        container.read(featureEnabledProvider(AscendFeature.googleSignIn)),
        isTrue,
      );
      expect(
        container.read(featureEnabledProvider(AscendFeature.appleSignIn)),
        isTrue,
      );
    },
  );

  testWidgets(
    'a key genuinely absent from a successfully-resolved map still falls back to its registry default, not blanket-true',
    (tester) async {
      final container = await pumpedContainer(
        tester,
        repository: FakeFeatureFlagsRepository(flags: const {}),
      );

      expect(
        container.read(featureEnabledProvider(AscendFeature.liveAi)),
        isFalse,
      );
      expect(
        container.read(featureEnabledProvider(AscendFeature.trainerDashboard)),
        isTrue,
      );
    },
  );

  testWidgets('the resolved map overrides the registry default when present', (
    tester,
  ) async {
    final container = await pumpedContainer(
      tester,
      repository: FakeFeatureFlagsRepository(
        flags: const {'LIVE_AI': true, 'TRAINER_DASHBOARD': false},
      ),
    );

    expect(
      container.read(featureEnabledProvider(AscendFeature.liveAi)),
      isTrue,
    );
    expect(
      container.read(featureEnabledProvider(AscendFeature.trainerDashboard)),
      isFalse,
    );
  });
}
