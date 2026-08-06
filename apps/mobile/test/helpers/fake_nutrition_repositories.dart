import 'package:mobile/features/nutrition/data/nutrition_summary_repository.dart';
import 'package:mobile/features/nutrition/domain/nutrition_dashboard_summary.dart';

const sampleNutritionDashboardSummary = NutritionDashboardSummary(
  proteinGrams: 42,
  proteinTargetGrams: 140,
  calorieTarget: 2200,
  calories: 850,
  hydrationMl: 750,
  hydrationTargetMl: 2500,
);

/// In-memory stand-in for the dashboard's nutrition summary call — avoids
/// hitting the network in widget tests the way the other Fake*Repository
/// classes do for their domains.
class FakeNutritionSummaryRepository implements NutritionSummaryRepository {
  FakeNutritionSummaryRepository({
    NutritionDashboardSummary? summary,
    this.shouldFail = false,
  }) : _summary = summary ?? sampleNutritionDashboardSummary;

  final NutritionDashboardSummary _summary;
  final bool shouldFail;

  @override
  Future<NutritionDashboardSummary> getTodaySummary() async {
    if (shouldFail) {
      throw Exception('network error');
    }
    return _summary;
  }
}
