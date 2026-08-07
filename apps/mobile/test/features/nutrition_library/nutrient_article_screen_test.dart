import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/nutrition_library/domain/nutrient_article.dart';
import 'package:mobile/features/nutrition_library/presentation/screens/nutrient_article_screen.dart';

import '../../helpers/fake_nutrition_library_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows the article body, food sources, and safety note', (
    tester,
  ) async {
    final repository = FakeNutritionLibraryRepository(
      articlesBySlug: {
        'protein': sampleNutrientArticle(
          slug: 'protein',
          body: 'Protein is made of amino acids.',
          foodSources: const [
            NutrientFoodSource(
              foodName: 'Chicken breast',
              amount: '31g protein per 100g',
            ),
          ],
        ),
      },
    );
    final container = await createTestContainer(
      signedIn: true,
      nutritionLibraryRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NutrientArticleScreen(slug: 'protein')),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Protein is made of amino acids.'), findsOneWidget);
    expect(find.text('Chicken breast — 31g protein per 100g'), findsOneWidget);
    expect(find.textContaining('not medical advice'), findsOneWidget);
  });

  testWidgets('tapping the bookmark icon saves the article', (tester) async {
    final repository = FakeNutritionLibraryRepository(
      articlesBySlug: {'protein': sampleNutrientArticle(slug: 'protein')},
    );
    final container = await createTestContainer(
      signedIn: true,
      nutritionLibraryRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NutrientArticleScreen(slug: 'protein')),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bookmark_border));
    await pumpForAsyncSettle(tester);

    expect(find.byIcon(Icons.bookmark), findsOneWidget);
    expect(repository.savedSlugs, contains('protein'));
  });
}
