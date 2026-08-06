import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/achievement_repository.dart';
import '../../domain/achievement.dart';

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepository(apiClient: ref.watch(apiClientProvider));
});

/// The full achievement catalog with this user's progress — screens that
/// only need "how many earned" (e.g. the Dashboard summary card) derive it
/// from this same list rather than a separate count endpoint.
final achievementsProvider = FutureProvider.autoDispose<List<Achievement>>((
  ref,
) {
  return ref.watch(achievementRepositoryProvider).list();
});
