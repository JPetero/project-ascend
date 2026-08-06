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
    'shows real logged meals grouped by type, not placeholder content',
    (tester) async {
      final mealEntryRepository = FakeMealEntryRepository();
      await mealEntryRepository.addEntry(
        foodId: sampleFood.id,
        mealType: MealType.breakfast,
        date: DateTime.now(),
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
      expect(find.textContaining('Cooked White Rice'), findsOneWidget);
      expect(find.text('Nothing logged yet.'), findsWidgets);
    },
  );

  testWidgets('quick-adding water updates the total shown', (tester) async {
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

    expect(find.text('0.00 L'), findsOneWidget);

    await tester.tap(find.text('+250ml'));
    await pumpForAsyncSettle(tester);

    expect(find.text('0.25 L'), findsOneWidget);
  });
}
