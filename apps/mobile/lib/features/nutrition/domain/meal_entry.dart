import 'meal_type.dart';

class MealEntryFoodRef {
  const MealEntryFoodRef({
    required this.id,
    required this.name,
    this.brand,
    required this.isEstimated,
  });

  final String id;
  final String name;
  final String? brand;
  final bool isEstimated;

  factory MealEntryFoodRef.fromJson(Map<String, dynamic> json) {
    return MealEntryFoodRef(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      isEstimated: json['isEstimated'] as bool? ?? true,
    );
  }
}

class MealEntryServingRef {
  const MealEntryServingRef({required this.id, required this.label});

  final String id;
  final String label;

  factory MealEntryServingRef.fromJson(Map<String, dynamic> json) {
    return MealEntryServingRef(
      id: json['id'] as String,
      label: json['label'] as String,
    );
  }
}

/// One logged food entry — the calorie/macro values are a snapshot taken
/// at log time, so later edits to the underlying [Food] never silently
/// rewrite history.
class MealEntry {
  const MealEntry({
    required this.id,
    required this.food,
    this.foodServing,
    required this.mealType,
    required this.date,
    required this.quantity,
    required this.calories,
    required this.proteinGrams,
    required this.carbGrams,
    required this.fatGrams,
    this.fiberGrams,
    this.notes,
  });

  final String id;
  final MealEntryFoodRef food;
  final MealEntryServingRef? foodServing;
  final MealType mealType;
  final DateTime date;
  final double quantity;
  final double calories;
  final double proteinGrams;
  final double carbGrams;
  final double fatGrams;
  final double? fiberGrams;
  final String? notes;

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      id: json['id'] as String,
      food: MealEntryFoodRef.fromJson(json['food'] as Map<String, dynamic>),
      foodServing: json['foodServing'] == null
          ? null
          : MealEntryServingRef.fromJson(
              json['foodServing'] as Map<String, dynamic>,
            ),
      mealType: mealTypeFromJson(json['mealType'] as String),
      date: DateTime.parse(json['date'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
      proteinGrams: (json['proteinGrams'] as num).toDouble(),
      carbGrams: (json['carbGrams'] as num).toDouble(),
      fatGrams: (json['fatGrams'] as num).toDouble(),
      fiberGrams: (json['fiberGrams'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }
}
