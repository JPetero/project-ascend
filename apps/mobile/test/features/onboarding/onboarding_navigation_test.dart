import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mobile/features/profile/domain/preferences_model.dart';
import 'package:mobile/features/profile/presentation/providers/preferences_controller.dart';

import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('advances pages and persists the selected companion', (
    tester,
  ) async {
    final container = await createTestContainer(signedIn: true);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Choose your companion'), findsOneWidget);

    await tester.tap(find.text('Nova'));
    await pumpForAsyncSettle(tester);

    expect(
      container.read(preferencesControllerProvider).asData?.value?.companion,
      Companion.nova,
    );

    await tester.tap(find.text('Next'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Tell us about yourself'), findsOneWidget);
    expect(find.text('Choose your companion'), findsNothing);
  });
}
