enum NutrientCategoryCode { macronutrient, mineral, vitamin }

NutrientCategoryCode nutrientCategoryCodeFromJson(String value) {
  switch (value) {
    case 'MINERAL':
      return NutrientCategoryCode.mineral;
    case 'VITAMIN':
      return NutrientCategoryCode.vitamin;
    default:
      return NutrientCategoryCode.macronutrient;
  }
}

String nutrientCategoryCodeToJson(NutrientCategoryCode code) {
  switch (code) {
    case NutrientCategoryCode.mineral:
      return 'MINERAL';
    case NutrientCategoryCode.vitamin:
      return 'VITAMIN';
    case NutrientCategoryCode.macronutrient:
      return 'MACRONUTRIENT';
  }
}

class NutrientArticleSummary {
  const NutrientArticleSummary({
    required this.id,
    required this.slug,
    required this.title,
    required this.summary,
  });

  final String id;
  final String slug;
  final String title;
  final String summary;

  factory NutrientArticleSummary.fromJson(Map<String, dynamic> json) {
    return NutrientArticleSummary(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
    );
  }
}

class NutrientCategory {
  const NutrientCategory({
    required this.code,
    required this.name,
    required this.description,
    this.articles = const [],
  });

  final NutrientCategoryCode code;
  final String name;
  final String description;
  final List<NutrientArticleSummary> articles;

  factory NutrientCategory.fromJson(Map<String, dynamic> json) {
    final articlesJson = json['articles'] as List<dynamic>?;
    return NutrientCategory(
      code: nutrientCategoryCodeFromJson(json['code'] as String),
      name: json['name'] as String,
      description: json['description'] as String,
      articles:
          articlesJson
              ?.map(
                (a) =>
                    NutrientArticleSummary.fromJson(a as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }
}

class NutrientFoodSource {
  const NutrientFoodSource({required this.foodName, required this.amount});

  final String foodName;
  final String amount;

  factory NutrientFoodSource.fromJson(Map<String, dynamic> json) {
    return NutrientFoodSource(
      foodName: json['foodName'] as String,
      amount: json['amount'] as String,
    );
  }
}

class NutrientReference {
  const NutrientReference({required this.label});

  final String label;

  factory NutrientReference.fromJson(Map<String, dynamic> json) {
    return NutrientReference(label: json['label'] as String);
  }
}

/// A single article in the free Ascend Nutrition Library — Build
/// Session 8 Part 11. [safetyNote] is always present: this is general
/// education, never a diagnosis or a specific supplement dose.
class NutrientArticle {
  const NutrientArticle({
    required this.id,
    required this.slug,
    required this.title,
    required this.summary,
    required this.body,
    required this.safetyNote,
    this.foodSources = const [],
    this.references = const [],
  });

  final String id;
  final String slug;
  final String title;
  final String summary;
  final String body;
  final String safetyNote;
  final List<NutrientFoodSource> foodSources;
  final List<NutrientReference> references;

  factory NutrientArticle.fromJson(Map<String, dynamic> json) {
    final foodSourcesJson = json['foodSources'] as List<dynamic>?;
    final referencesJson = json['references'] as List<dynamic>?;
    return NutrientArticle(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      body: json['body'] as String,
      safetyNote: json['safetyNote'] as String,
      foodSources:
          foodSourcesJson
              ?.map(
                (f) => NutrientFoodSource.fromJson(f as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      references:
          referencesJson
              ?.map(
                (r) => NutrientReference.fromJson(r as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }
}
