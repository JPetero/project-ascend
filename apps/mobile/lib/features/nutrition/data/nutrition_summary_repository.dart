import '../../../core/networking/api_client.dart';
import '../domain/nutrition_dashboard_summary.dart';

/// Thin read-only client for the three Nutrition backend endpoints the
/// dashboard needs. Deliberately not the full Nutrition repository
/// (no food search, logging, or target editing) — see
/// `NutritionDashboardSummary`'s doc comment.
class NutritionSummaryRepository {
  NutritionSummaryRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<NutritionDashboardSummary> getTodaySummary() async {
    final today = DateTime.now();
    final dateStr =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    final results = await Future.wait([
      _apiClient.get(
        '/nutrition-log/summary',
        (data) => data as Map<String, dynamic>,
        query: {'date': dateStr},
      ),
      _apiClient.get('/macro-targets', (data) => data as Map<String, dynamic>),
      _apiClient.get(
        '/water',
        (data) => data as Map<String, dynamic>,
        query: {'date': dateStr},
      ),
    ]);

    final logSummary = results[0].data!;
    final targets = results[1].data!;
    final water = results[2].data!;

    return NutritionDashboardSummary(
      proteinGrams: (logSummary['proteinGrams'] as num).toDouble(),
      proteinTargetGrams: targets['proteinGramsTarget'] as int,
      calorieTarget: targets['calorieTarget'] as int,
      calories: (logSummary['calories'] as num).toDouble(),
      hydrationMl: water['totalMl'] as int,
      hydrationTargetMl: NutritionDashboardSummary.defaultHydrationTargetMl,
    );
  }
}
