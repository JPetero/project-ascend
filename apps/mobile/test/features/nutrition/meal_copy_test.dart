import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/features/nutrition/domain/meal_type.dart';
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
    'copies yesterday\'s meals into today via the Meals section action',
    (tester) async {
      final mealEntryRepository = FakeMealEntryRepository();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await mealEntryRepository.addEntry(
        foodId: sampleFood.id,
        mealType: MealType.lunch,
        date: yesterday,
        quantity: 1,
      );

      final container = await createTestContainer(
        signedIn: true,
        initialProfile: _onboardedProfile,
        mealEntryRepository: mealEntryRepository,
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

      expect(find.byType(MealPrepScreen), findsOneWidget);
      expect(find.textContaining(sampleFood.name), findsNothing);

      final copyAction = find.text('Copy yesterday');
      await tester.scrollUntilVisible(
        copyAction,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await pumpForAsyncSettle(tester, frames: 6);
      await tester.tap(copyAction);
      await pumpForAsyncSettle(tester);

      expect(find.text('Copied 1 entry from yesterday.'), findsOneWidget);

      final copiedEntry = find.textContaining(sampleFood.name);
      await tester.scrollUntilVisible(
        copiedEntry,
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(copiedEntry, findsOneWidget);
    },
  );

  testWidgets('reports honestly when there is nothing to copy from yesterday', (
    tester,
  ) async {
    final container = await createTestContainer(
      signedIn: true,
      initialProfile: _onboardedProfile,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AscendApp()),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Fuel'));
    await pumpForAsyncSettle(tester);

    final copyAction = find.text('Copy yesterday');
    await tester.scrollUntilVisible(
      copyAction,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpForAsyncSettle(tester, frames: 6);
    await tester.tap(copyAction);
    await pumpForAsyncSettle(tester);

    expect(find.text('No meals logged yesterday to copy.'), findsOneWidget);
  });
}
