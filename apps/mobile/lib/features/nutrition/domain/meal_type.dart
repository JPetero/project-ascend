enum MealType { breakfast, lunch, dinner, snack }

MealType mealTypeFromJson(String value) => MealType.values.firstWhere(
  (e) => e.name.toUpperCase() == value,
  orElse: () => MealType.snack,
);

String mealTypeToJson(MealType type) => type.name.toUpperCase();

String mealTypeLabel(MealType type) {
  switch (type) {
    case MealType.breakfast:
      return 'Breakfast';
    case MealType.lunch:
      return 'Lunch';
    case MealType.dinner:
      return 'Dinner';
    case MealType.snack:
      return 'Snacks';
  }
}
