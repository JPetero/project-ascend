import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/water_repository.dart';

final waterRepositoryProvider = Provider<WaterRepository>((ref) {
  return WaterRepository(apiClient: ref.watch(apiClientProvider));
});

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Today's logged water. Screens invalidate this provider after a quick
/// add so the total stays current — see `MealPrepScreen`.
final todaysWaterProvider = FutureProvider.autoDispose<DailyWater>((ref) {
  return ref.watch(waterRepositoryProvider).getDaily(_today());
});
