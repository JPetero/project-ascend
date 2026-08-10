import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/entitlements/capability_provider.dart';
import 'package:mobile/core/entitlements/capability.dart';
import 'package:mobile/features/feature_flags/presentation/providers/feature_flags_provider.dart';
import 'package:mobile/features/promote/presentation/providers/promote_controller.dart';
import 'package:mobile/features/promote/presentation/screens/promote_screen.dart';

import '../../helpers/fake_promote_repository.dart';
import '../../helpers/pump_helpers.dart';

/// ASCEND_PROMOTE defaults closed (Build Session 13 continuation Part A)
/// — every test below that expects the "new campaign" action opts in
/// explicitly, the same as production requires an admin to.
final _promoteEnabled = featureFlagsProvider.overrideWith(
  (ref) async => {'ASCEND_PROMOTE': true},
);

void main() {
  testWidgets(
    'a Free-tier user sees an honest locked state, not a fake preview',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            planTierProvider.overrideWithValue(PlanTier.free),
            promoteRepositoryProvider.overrideWithValue(
              FakePromoteRepository(),
            ),
          ],
          child: const MaterialApp(home: PromoteScreen()),
        ),
      );

      expect(
        find.text('Ascend Promote is a Premium creator tool'),
        findsOneWidget,
      );
      expect(find.byType(FloatingActionButton), findsNothing);
    },
  );

  testWidgets('a Premium-tier user with no campaigns sees an empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planTierProvider.overrideWithValue(PlanTier.premium),
          promoteRepositoryProvider.overrideWithValue(FakePromoteRepository()),
          _promoteEnabled,
        ],
        child: const MaterialApp(home: PromoteScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('No campaigns yet'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets(
    'the new-campaign action is hidden while ASCEND_PROMOTE is disabled, even for Premium',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            planTierProvider.overrideWithValue(PlanTier.premium),
            promoteRepositoryProvider.overrideWithValue(
              FakePromoteRepository(),
            ),
          ],
          child: const MaterialApp(home: PromoteScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.text('No campaigns yet'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    },
  );

  testWidgets('a Premium-tier user sees their own campaigns listed', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planTierProvider.overrideWithValue(PlanTier.premium),
          promoteRepositoryProvider.overrideWithValue(
            FakePromoteRepository(campaigns: [sampleCampaign()]),
          ),
        ],
        child: const MaterialApp(home: PromoteScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('50 USD budget'), findsOneWidget);
    expect(find.text('Pending review'), findsOneWidget);
  });
}
