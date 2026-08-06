import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/saved_meal_repository.dart';
import '../../domain/saved_meal.dart';

final savedMealRepositoryProvider = Provider<SavedMealRepository>((ref) {
  return SavedMealRepository(apiClient: ref.watch(apiClientProvider));
});

/// The user's saved meals. Screens invalidate this after create/delete so
/// the list stays current — see `MealPrepScreen`.
final savedMealsProvider = FutureProvider.autoDispose<List<SavedMeal>>((ref) {
  return ref.watch(savedMealRepositoryProvider).list();
});
