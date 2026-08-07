import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/entitlements/capability_provider.dart';
import 'package:mobile/core/entitlements/capability.dart';
import 'package:mobile/features/notifications/presentation/providers/notifications_controller.dart';
import 'package:mobile/features/vision/presentation/screens/vision_screen.dart';

import '../../helpers/fake_notifications_repository.dart';

void main() {
  testWidgets(
    'a Free-tier user sees an honest locked state, not a fake preview',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            planTierProvider.overrideWithValue(PlanTier.free),
            notificationsRepositoryProvider.overrideWithValue(
              FakeNotificationsRepository(),
            ),
          ],
          child: const MaterialApp(home: VisionScreen()),
        ),
      );

      expect(find.text('Vision is a Premium destination'), findsOneWidget);
      expect(find.text('Vision is on its way'), findsNothing);
    },
  );

  testWidgets(
    'a Premium-tier user sees the modular shell listing every future mode, '
    'not a fake preview',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            planTierProvider.overrideWithValue(PlanTier.premium),
            notificationsRepositoryProvider.overrideWithValue(
              FakeNotificationsRepository(),
            ),
          ],
          child: const MaterialApp(home: VisionScreen()),
        ),
      );

      expect(find.text('Form Coach'), findsOneWidget);
      expect(find.text('Rep Counter'), findsOneWidget);
      expect(find.text('Progress Scan'), findsOneWidget);
      expect(find.text('Food Scan'), findsOneWidget);
      expect(find.text('Sport Capture'), findsOneWidget);
      expect(find.text('Outfit Guidance'), findsOneWidget);
      expect(find.text('Vision is a Premium destination'), findsNothing);
    },
  );
}
