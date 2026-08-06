import 'food.dart';

/// A calorie/macro snapshot, computed the same way
/// `NutritionLogService.computeMacroSnapshot` computes it server-side (see
/// services/api/src/modules/nutrition-log/nutrition-log.service.ts) —
/// scaling a [Food]'s per-serving values by how many servings were logged.
/// Mirrored client-side so a meal entry can be logged (and its calories
/// shown) while offline; the server recomputes authoritatively once the
/// create syncs, and that value always wins on reconciliation.
class MacroSnapshot {
  const MacroSnapshot({
    required this.calories,
    required this.proteinGrams,
    required this.carbGrams,
    required this.fatGrams,
    this.fiberGrams,
  });

  final double calories;
  final double proteinGrams;
  final double carbGrams;
  final double fatGrams;
  final double? fiberGrams;
}

double _round1(double value) => (value * 10).round() / 10;

MacroSnapshot computeMacroSnapshot({
  required Food food,
  FoodServing? serving,
  required double quantity,
}) {
  final double multiplier;
  if (serving?.grams != null && food.servingGrams != null) {
    multiplier = (serving!.grams! * quantity) / food.servingGrams!;
  } else {
    // The serving option isn't gram-convertible (e.g. "1 piece") — the
    // quantity directly multiplies the food's own reference serving, same
    // as the backend's fallback branch.
    multiplier = quantity;
  }

  return MacroSnapshot(
    calories: _round1(food.caloriesPerServing * multiplier),
    proteinGrams: _round1(food.proteinGramsPerServing * multiplier),
    carbGrams: _round1(food.carbGramsPerServing * multiplier),
    fatGrams: _round1(food.fatGramsPerServing * multiplier),
    fiberGrams: food.fiberGramsPerServing != null
        ? _round1(food.fiberGramsPerServing! * multiplier)
        : null,
  );
}
