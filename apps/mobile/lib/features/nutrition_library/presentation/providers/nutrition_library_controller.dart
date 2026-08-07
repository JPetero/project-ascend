import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/nutrition_library_repository.dart';
import '../../domain/nutrient_article.dart';

final nutritionLibraryRepositoryProvider = Provider<NutritionLibraryRepository>(
  (ref) {
    return NutritionLibraryRepository(apiClient: ref.watch(apiClientProvider));
  },
);

/// The library's categories, each with its article summaries — Build
/// Session 8 Part 11. Free on every tier (AppCapability.nutritionLibrary).
class NutrientCategoriesController
    extends StateNotifier<AsyncValue<List<NutrientCategory>>> {
  NutrientCategoriesController({required NutritionLibraryRepository repository})
    : _repository = repository,
      super(const AsyncValue.loading()) {
    load();
  }

  final NutritionLibraryRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final categories = await _repository.listCategories();
      state = AsyncValue.data(categories);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final nutrientCategoriesControllerProvider =
    StateNotifierProvider.autoDispose<
      NutrientCategoriesController,
      AsyncValue<List<NutrientCategory>>
    >((ref) {
      return NutrientCategoriesController(
        repository: ref.watch(nutritionLibraryRepositoryProvider),
      );
    });

final nutrientArticleProvider = FutureProvider.autoDispose
    .family<NutrientArticle, String>((ref, slug) {
      return ref.watch(nutritionLibraryRepositoryProvider).getArticle(slug);
    });

/// The caller's saved articles — kept separate from article detail so
/// toggling save/unsave from any screen updates every screen watching
/// this provider.
class SavedNutrientArticlesController
    extends StateNotifier<AsyncValue<List<NutrientArticleSummary>>> {
  SavedNutrientArticlesController({
    required NutritionLibraryRepository repository,
  }) : _repository = repository,
       super(const AsyncValue.loading()) {
    load();
  }

  final NutritionLibraryRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final saved = await _repository.listSaved();
      state = AsyncValue.data(saved);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  bool isSaved(String slug) {
    return state.asData?.value.any((a) => a.slug == slug) ?? false;
  }

  Future<void> toggle(String slug) async {
    final currentlySaved = isSaved(slug);
    try {
      if (currentlySaved) {
        await _repository.unsave(slug);
      } else {
        await _repository.save(slug);
      }
      await load();
    } catch (_) {
      // Leave state as-is on failure — the toggle simply appears not to
      // have taken effect, which is honest since it didn't.
    }
  }
}

final savedNutrientArticlesControllerProvider =
    StateNotifierProvider<
      SavedNutrientArticlesController,
      AsyncValue<List<NutrientArticleSummary>>
    >((ref) {
      return SavedNutrientArticlesController(
        repository: ref.watch(nutritionLibraryRepositoryProvider),
      );
    });
