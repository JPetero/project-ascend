import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/features/nutrition/presentation/screens/macro_target_editor_screen.dart';
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
    'edits and saves macro targets from the Meal Prep header action',
    (tester) async {
      final macroTargetRepository = FakeMacroTargetRepository();

      final container = await createTestContainer(
        signedIn: true,
        initialProfile: _onboardedProfile,
        macroTargetRepository: macroTargetRepository,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AscendApp(),
        ),
      );
      await pumpForAsyncSettle(tester);

      await tester.tap(find.text('Meal Prep'));
      await pumpForAsyncSettle(tester);

      expect(find.byType(MealPrepScreen), findsOneWidget);

      await tester.tap(find.text('Edit targets'));
      await pumpForAsyncSettle(tester);

      expect(find.byType(MacroTargetEditorScreen), findsOneWidget);

      final caloriesField = find.widgetWithText(TextFormField, 'Calories');
      expect(
        tester.widget<TextFormField>(caloriesField).controller!.text,
        '2200',
      );

      await tester.enterText(caloriesField, '2400');
      await tester.tap(find.text('Save targets'));
      await pumpForAsyncSettle(tester);

      expect(macroTargetRepository.upsertCalls, hasLength(1));
      expect(macroTargetRepository.upsertCalls.single.calorieTarget, 2400);
      expect(find.byType(MacroTargetEditorScreen), findsNothing);
      expect(find.byType(MealPrepScreen), findsOneWidget);
    },
  );
}
