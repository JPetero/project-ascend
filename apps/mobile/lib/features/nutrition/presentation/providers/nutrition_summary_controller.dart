import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/nutrition_summary_repository.dart';
import '../../domain/nutrition_dashboard_summary.dart';

final nutritionSummaryRepositoryProvider = Provider<NutritionSummaryRepository>(
  (ref) {
    return NutritionSummaryRepository(apiClient: ref.watch(apiClientProvider));
  },
);

final nutritionDashboardSummaryProvider =
    FutureProvider.autoDispose<NutritionDashboardSummary>((ref) {
      return ref.watch(nutritionSummaryRepositoryProvider).getTodaySummary();
    });
