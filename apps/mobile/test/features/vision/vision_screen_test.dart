import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/entitlements/capability_provider.dart';
import 'package:mobile/core/entitlements/capability.dart';
import 'package:mobile/features/vision/presentation/screens/vision_screen.dart';

void main() {
  testWidgets(
    'a Free-tier user sees an honest locked state, not a fake preview',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [planTierProvider.overrideWithValue(PlanTier.free)],
          child: const MaterialApp(home: VisionScreen()),
        ),
      );

      expect(find.text('Vision is a Premium destination'), findsOneWidget);
      expect(find.text('Vision is on its way'), findsNothing);
    },
  );

  testWidgets(
    'a Premium-tier user sees the honest coming-soon state, not a fake preview',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [planTierProvider.overrideWithValue(PlanTier.premium)],
          child: const MaterialApp(home: VisionScreen()),
        ),
      );

      expect(find.text('Vision is on its way'), findsOneWidget);
      expect(find.text('Vision is a Premium destination'), findsNothing);
    },
  );
}
