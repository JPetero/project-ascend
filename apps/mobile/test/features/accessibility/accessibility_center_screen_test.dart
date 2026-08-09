import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/accessibility/presentation/screens/accessibility_center_screen.dart';
import 'package:mobile/features/profile/domain/preferences_model.dart';
import 'package:mobile/features/profile/presentation/providers/preferences_controller.dart';

import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

PreferencesModel _preferences({
  bool reducedMotion = false,
  double textScale = 1.0,
}) {
  return PreferencesModel(
    companion: Companion.atlas,
    companionMode: CompanionMode.standard,
    themeMode: AppThemeMode.system,
    reducedMotion: reducedMotion,
    notificationsEnabled: true,
    aiMemoryEnabled: false,
    textScale: textScale,
  );
}

void main() {
  testWidgets('reflects the stored text scale and reduced-motion value', (
    tester,
  ) async {
    final container = await createTestContainer(
      signedIn: true,
      initialPreferences: _preferences(reducedMotion: true, textScale: 1.15),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AccessibilityCenterScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    final segmented = tester.widget<SegmentedButton<double>>(
      find.byType(SegmentedButton<double>),
    );
    expect(segmented.selected, {1.15});

    final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(toggle.value, isTrue);
  });

  testWidgets('picking a text size updates the preference', (tester) async {
    final container = await createTestContainer(
      signedIn: true,
      initialPreferences: _preferences(),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AccessibilityCenterScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Large'));
    await pumpForAsyncSettle(tester);

    final preferences = container
        .read(preferencesControllerProvider)
        .asData
        ?.value;
    expect(preferences?.textScale, 1.15);
  });
}
