import 'package:mobile/features/nutrition_library/data/nutrition_library_repository.dart';
import 'package:mobile/features/nutrition_library/domain/nutrient_article.dart';

NutrientArticleSummary sampleArticleSummary({
  String id = 'article-1',
  String slug = 'protein',
  String title = 'Protein',
  String summary =
      'Protein supplies amino acids your body uses to build muscle.',
}) {
  return NutrientArticleSummary(
    id: id,
    slug: slug,
    title: title,
    summary: summary,
  );
}

NutrientCategory sampleNutrientCategory({
  NutrientCategoryCode code = NutrientCategoryCode.macronutrient,
  String name = 'Macronutrients',
  String description = 'Protein, carbohydrates, fat, and fiber.',
  List<NutrientArticleSummary> articles = const [],
}) {
  return NutrientCategory(
    code: code,
    name: name,
    description: description,
    articles: articles,
  );
}

NutrientArticle sampleNutrientArticle({
  String id = 'article-1',
  String slug = 'protein',
  String title = 'Protein',
  String summary =
      'Protein supplies amino acids your body uses to build muscle.',
  String body = 'Protein is made of amino acids.',
  String safetyNote =
      'This article is general nutrition education, not medical advice.',
  List<NutrientFoodSource> foodSources = const [],
  List<NutrientReference> references = const [],
}) {
  return NutrientArticle(
    id: id,
    slug: slug,
    title: title,
    summary: summary,
    body: body,
    safetyNote: safetyNote,
    foodSources: foodSources,
    references: references,
  );
}

/// In-memory stand-in for [NutritionLibraryRepository].
class FakeNutritionLibraryRepository implements NutritionLibraryRepository {
  FakeNutritionLibraryRepository({
    List<NutrientCategory>? categories,
    Map<String, NutrientArticle>? articlesBySlug,
    List<String>? savedSlugs,
  }) : categories =
           categories ??
           [
             sampleNutrientCategory(articles: [sampleArticleSummary()]),
           ],
       articlesBySlug = articlesBySlug ?? {'protein': sampleNutrientArticle()},
       savedSlugs = savedSlugs ?? [];

  final List<NutrientCategory> categories;
  final Map<String, NutrientArticle> articlesBySlug;
  final List<String> savedSlugs;

  @override
  Future<List<NutrientCategory>> listCategories() async =>
      List.unmodifiable(categories);

  @override
  Future<NutrientArticle> getArticle(String slug) async =>
      articlesBySlug[slug] ?? sampleNutrientArticle(slug: slug);

  @override
  Future<List<NutrientArticleSummary>> listSaved() async {
    return [
      for (final slug in savedSlugs)
        NutrientArticleSummary(
          id: 'article-$slug',
          slug: slug,
          title: articlesBySlug[slug]?.title ?? slug,
          summary: articlesBySlug[slug]?.summary ?? '',
        ),
    ];
  }

  @override
  Future<void> save(String slug) async {
    if (!savedSlugs.contains(slug)) savedSlugs.add(slug);
  }

  @override
  Future<void> unsave(String slug) async {
    savedSlugs.remove(slug);
  }
}
