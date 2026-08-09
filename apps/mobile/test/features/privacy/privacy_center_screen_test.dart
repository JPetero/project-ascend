import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/privacy/presentation/screens/privacy_center_screen.dart';
import 'package:mobile/features/profile/domain/preferences_model.dart';
import 'package:mobile/features/profile/presentation/providers/preferences_controller.dart';

import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets(
    'shows the AI memory and conversation history toggles at their current values',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        initialPreferences: const PreferencesModel(
          companion: Companion.atlas,
          companionMode: CompanionMode.standard,
          themeMode: AppThemeMode.system,
          reducedMotion: false,
          notificationsEnabled: true,
          aiMemoryEnabled: true,
          conversationHistoryEnabled: false,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: PrivacyCenterScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      final switches = tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .toList();
      expect(switches[0].value, isTrue);
      expect(switches[1].value, isFalse);
    },
  );

  testWidgets('toggling AI memory updates the preference', (tester) async {
    final container = await createTestContainer(
      signedIn: true,
      initialPreferences: const PreferencesModel(
        companion: Companion.atlas,
        companionMode: CompanionMode.standard,
        themeMode: AppThemeMode.system,
        reducedMotion: false,
        notificationsEnabled: true,
        aiMemoryEnabled: false,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PrivacyCenterScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.byType(SwitchListTile).first);
    await pumpForAsyncSettle(tester);

    final preferences = container
        .read(preferencesControllerProvider)
        .asData
        ?.value;
    expect(preferences?.aiMemoryEnabled, isTrue);
  });
}
