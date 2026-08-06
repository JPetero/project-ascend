import 'meal_entry.dart';

class SavedMealItem {
  const SavedMealItem({
    required this.id,
    required this.food,
    this.foodServing,
    required this.quantity,
  });

  final MealEntryFoodRef food;
  final MealEntryServingRef? foodServing;
  final double quantity;
  final String id;

  factory SavedMealItem.fromJson(Map<String, dynamic> json) {
    return SavedMealItem(
      id: json['id'] as String,
      food: MealEntryFoodRef.fromJson(json['food'] as Map<String, dynamic>),
      foodServing: json['foodServing'] == null
          ? null
          : MealEntryServingRef.fromJson(
              json['foodServing'] as Map<String, dynamic>,
            ),
      quantity: (json['quantity'] as num).toDouble(),
    );
  }
}

/// A named, reusable group of food entries a user can log in one action —
/// see packages/docs/product/user-scenario-bible.md Part 7.
class SavedMeal {
  const SavedMeal({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.items,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final List<SavedMealItem> items;

  factory SavedMeal.fromJson(Map<String, dynamic> json) {
    return SavedMeal(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      items: (json['items'] as List<dynamic>)
          .map((i) => SavedMealItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}
