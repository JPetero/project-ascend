class FoodServing {
  const FoodServing({
    required this.id,
    required this.label,
    this.grams,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final double? grams;
  final bool isDefault;

  factory FoodServing.fromJson(Map<String, dynamic> json) {
    return FoodServing(
      id: json['id'] as String,
      label: json['label'] as String,
      grams: (json['grams'] as num?)?.toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

/// A food someone can log a [MealEntry] against — either from the shared
/// seed catalog or a user's own custom food. Values are per-serving
/// estimates, not a claim of lab-verified accuracy — see
/// packages/docs/product/wellness-ethics-bible.md.
class Food {
  const Food({
    required this.id,
    required this.name,
    this.alternateName,
    this.brand,
    required this.isOwnedByCurrentUser,
    required this.servingDescription,
    this.servingGrams,
    required this.caloriesPerServing,
    required this.proteinGramsPerServing,
    required this.carbGramsPerServing,
    required this.fatGramsPerServing,
    this.fiberGramsPerServing,
    this.sodiumMgPerServing,
    required this.isEstimated,
    this.servings = const [],
  });

  final String id;
  final String name;
  final String? alternateName;
  final String? brand;
  final bool isOwnedByCurrentUser;
  final String servingDescription;
  final double? servingGrams;
  final double caloriesPerServing;
  final double proteinGramsPerServing;
  final double carbGramsPerServing;
  final double fatGramsPerServing;
  final double? fiberGramsPerServing;
  final double? sodiumMgPerServing;
  final bool isEstimated;
  final List<FoodServing> servings;

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] as String,
      name: json['name'] as String,
      alternateName: json['alternateName'] as String?,
      brand: json['brand'] as String?,
      isOwnedByCurrentUser: json['isOwnedByCurrentUser'] as bool? ?? false,
      servingDescription: json['servingDescription'] as String,
      servingGrams: (json['servingGrams'] as num?)?.toDouble(),
      caloriesPerServing: (json['caloriesPerServing'] as num).toDouble(),
      proteinGramsPerServing: (json['proteinGramsPerServing'] as num)
          .toDouble(),
      carbGramsPerServing: (json['carbGramsPerServing'] as num).toDouble(),
      fatGramsPerServing: (json['fatGramsPerServing'] as num).toDouble(),
      fiberGramsPerServing: (json['fiberGramsPerServing'] as num?)?.toDouble(),
      sodiumMgPerServing: (json['sodiumMgPerServing'] as num?)?.toDouble(),
      isEstimated: json['isEstimated'] as bool? ?? true,
      servings: (json['servings'] as List<dynamic>? ?? [])
          .map((s) => FoodServing.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
