import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/nutrition_library/presentation/screens/nutrition_library_screen.dart';

import '../../helpers/fake_nutrition_library_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('lists categories with their articles', (tester) async {
    final repository = FakeNutritionLibraryRepository(
      categories: [
        sampleNutrientCategory(
          name: 'Macronutrients',
          articles: [sampleArticleSummary(title: 'Protein')],
        ),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      nutritionLibraryRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NutritionLibraryScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Macronutrients'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
  });
}
