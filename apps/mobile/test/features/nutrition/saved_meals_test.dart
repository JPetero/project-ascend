import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/core/design_system/widgets/ascend_buttons.dart';
import 'package:mobile/features/nutrition/data/saved_meal_repository.dart';
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
  testWidgets('shows saved meals and logs one into today\'s entries', (
    tester,
  ) async {
    final mealEntryRepository = FakeMealEntryRepository();
    final savedMealRepository = FakeSavedMealRepository(
      mealEntryRepository: mealEntryRepository,
    );
    await savedMealRepository.create(
      name: 'Rice and eggs',
      items: [SavedMealItemInput(foodId: sampleFood.id, quantity: 1)],
    );

    final container = await createTestContainer(
      signedIn: true,
      initialProfile: _onboardedProfile,
      savedMealRepository: savedMealRepository,
      mealEntryRepository: mealEntryRepository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AscendApp()),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Meal Prep'));
    await pumpForAsyncSettle(tester);

    expect(find.byType(MealPrepScreen), findsOneWidget);

    final savedMealTitle = find.text('Rice and eggs');
    await tester.scrollUntilVisible(
      savedMealTitle,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(savedMealTitle, findsOneWidget);
    expect(find.text('1 item'), findsOneWidget);

    final logButton = find.widgetWithText(AscendGhostButton, 'Log');
    await tester.scrollUntilVisible(
      logButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // scrollUntilVisible's final Scrollable.ensureVisible animation isn't
    // pumped to completion by the time it returns, so settle it before
    // tapping or the offset can land mid-scroll and miss the button.
    await pumpForAsyncSettle(tester, frames: 6);
    await tester.tap(logButton);
    await pumpForAsyncSettle(tester);

    expect(find.text('Breakfast'), findsWidgets);
    await tester.tap(find.text('Breakfast').last);
    await pumpForAsyncSettle(tester);

    final loggedEntry = find.textContaining(sampleFood.name);
    await tester.scrollUntilVisible(
      loggedEntry,
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(loggedEntry, findsOneWidget);
  });

  testWidgets('shows an honest empty state with no saved meals', (
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

    await tester.tap(find.text('Meal Prep'));
    await pumpForAsyncSettle(tester);

    final emptyState = find.text('No saved meals yet');
    await tester.scrollUntilVisible(
      emptyState,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(emptyState, findsOneWidget);
  });
}
