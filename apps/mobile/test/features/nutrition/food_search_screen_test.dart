import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/features/nutrition/presentation/screens/meal_prep_screen.dart';
import 'package:mobile/features/profile/domain/profile_model.dart';

import '../../helpers/fake_nutrition_repositories.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

const _onboardedProfile = ProfileModel(
  firstName: 'Ada',
  languageCode: 'en',
  timezone: 'UTC',
  unitSystem: UnitSystem.metric,
  sexForCalculations: SexForCalculations.unspecified,
  onboardingCompleted: true,
  onboardingStep: 8,
);

void main() {
  testWidgets(
    'searching, selecting, and logging a food adds it to the meal list',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        initialProfile: _onboardedProfile,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AscendApp(),
        ),
      );
      await pumpForAsyncSettle(tester);

      await tester.tap(find.text('Fuel'));
      await pumpForAsyncSettle(tester);

      final addToBreakfast = find.widgetWithIcon(
        IconButton,
        Icons.add_circle_outline,
      );
      await tester.tap(addToBreakfast.first);
      await pumpForAsyncSettle(tester);

      expect(find.text('Add to Breakfast'), findsOneWidget);
      expect(find.textContaining(sampleFood.name), findsOneWidget);

      await tester.tap(find.textContaining(sampleFood.name));
      await pumpForAsyncSettle(tester);

      expect(find.text('Log it'), findsOneWidget);

      await tester.tap(find.text('Log it'));
      await pumpForAsyncSettle(tester);

      expect(find.byType(MealPrepScreen), findsOneWidget);
      expect(find.textContaining(sampleFood.name), findsOneWidget);
    },
  );
}
