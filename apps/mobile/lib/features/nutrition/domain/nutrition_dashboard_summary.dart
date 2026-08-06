/// Just enough of today's nutrition picture to power the dashboard's
/// protein and hydration cards with real numbers — not the full Nutrition
/// feature (food search, meal logging, serving selection, ...), which is
/// intentionally out of scope for this pass. See
/// `packages/docs/roadmap.md` for the full Nutrition feature.
class NutritionDashboardSummary {
  const NutritionDashboardSummary({
    required this.proteinGrams,
    required this.proteinTargetGrams,
    required this.calorieTarget,
    required this.calories,
    required this.hydrationMl,
    required this.hydrationTargetMl,
  });

  final double proteinGrams;
  final int proteinTargetGrams;
  final int calorieTarget;
  final double calories;
  final int hydrationMl;
  final int hydrationTargetMl;

  /// A widely-used general hydration guideline (not personalized) — used
  /// only as a display target since there is no dedicated water target
  /// field in `MacroTarget` yet. Clearly a fallback, not a measurement.
  static const defaultHydrationTargetMl = 2500;
}
