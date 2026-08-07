import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/nutrition_library/presentation/providers/nutrition_library_controller.dart';

import '../../helpers/fake_nutrition_library_repository.dart';

void main() {
  group('NutrientCategoriesController', () {
    test('loads categories on construction', () async {
      final repository = FakeNutritionLibraryRepository();
      final controller = NutrientCategoriesController(repository: repository);
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.asData?.value, hasLength(1));
    });
  });

  group('SavedNutrientArticlesController', () {
    test('loads the saved list and reports isSaved correctly', () async {
      final repository = FakeNutritionLibraryRepository(
        savedSlugs: ['protein'],
      );
      final controller = SavedNutrientArticlesController(
        repository: repository,
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(controller.isSaved('protein'), isTrue);
      expect(controller.isSaved('iron'), isFalse);
    });

    test('toggle saves an unsaved article', () async {
      final repository = FakeNutritionLibraryRepository();
      final controller = SavedNutrientArticlesController(
        repository: repository,
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      await controller.toggle('protein');

      expect(controller.isSaved('protein'), isTrue);
      expect(repository.savedSlugs, contains('protein'));
    });

    test('toggle unsaves an already-saved article', () async {
      final repository = FakeNutritionLibraryRepository(
        savedSlugs: ['protein'],
      );
      final controller = SavedNutrientArticlesController(
        repository: repository,
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      await controller.toggle('protein');

      expect(controller.isSaved('protein'), isFalse);
      expect(repository.savedSlugs, isEmpty);
    });
  });
}
