import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/nutrition/presentation/providers/food_controller.dart';
import 'package:mobile/features/nutrition/presentation/screens/custom_food_editor_screen.dart';

import '../../helpers/fake_nutrition_repositories.dart';
import '../../helpers/pump_helpers.dart';

void main() {
  testWidgets('creates a custom food and returns it to the caller', (
    tester,
  ) async {
    final foodRepository = FakeFoodRepository();
    final container = ProviderContainer(
      overrides: [foodRepositoryProvider.overrideWithValue(foodRepository)],
    );
    addTearDown(container.dispose);

    Object? returnedFood;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                returnedFood = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CustomFoodEditorScreen(),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await pumpForAsyncSettle(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Food name'),
      'Peanut Butter',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Serving size (e.g. "1 cup cooked")'),
      '2 tbsp (32 g)',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Calories per serving'),
      '190',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Protein (g) per serving'),
      '8',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Carbs (g) per serving'),
      '6',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Fat (g) per serving'),
      '16',
    );

    await tester.tap(find.text('Save food'));
    await pumpForAsyncSettle(tester);

    expect(foodRepository.foods.any((f) => f.name == 'Peanut Butter'), isTrue);
    expect(returnedFood, isNotNull);
  });
}
