import '../../../core/networking/api_client.dart';
import '../domain/nutrient_article.dart';

/// Thin client for services/api/src/modules/nutrition-library — Build
/// Session 8 Part 11's free Ascend Nutrition Library.
class NutritionLibraryRepository {
  NutritionLibraryRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<NutrientCategory>> listCategories() async {
    final envelope = await _apiClient.get(
      '/nutrition-library/categories',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map((c) => NutrientCategory.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<NutrientArticle> getArticle(String slug) async {
    final envelope = await _apiClient.get(
      '/nutrition-library/articles/$slug',
      (data) => data as Map<String, dynamic>,
    );
    return NutrientArticle.fromJson(envelope.data!);
  }

  Future<List<NutrientArticleSummary>> listSaved() async {
    final envelope = await _apiClient.get(
      '/nutrition-library/saved',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map((a) => NutrientArticleSummary.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(String slug) async {
    await _apiClient.post(
      '/nutrition-library/articles/$slug/save',
      (_) => null,
    );
  }

  Future<void> unsave(String slug) async {
    await _apiClient.delete(
      '/nutrition-library/articles/$slug/save',
      (_) => null,
    );
  }
}
