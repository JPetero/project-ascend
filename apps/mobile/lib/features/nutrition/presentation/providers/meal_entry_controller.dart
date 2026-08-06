import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/meal_entry_repository.dart';
import '../../domain/meal_entry.dart';

final mealEntryRepositoryProvider = Provider<MealEntryRepository>((ref) {
  return MealEntryRepository(apiClient: ref.watch(apiClientProvider));
});

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Today's logged meal entries. Screens invalidate this provider after any
/// add/delete/copy so the list stays current — see `MealPrepScreen`.
final todaysMealEntriesProvider = FutureProvider.autoDispose<List<MealEntry>>((
  ref,
) {
  return ref.watch(mealEntryRepositoryProvider).listForDate(_today());
});
