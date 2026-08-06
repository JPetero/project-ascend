import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/workout_history_repository.dart';
import '../../domain/workout_history_entry.dart';

final workoutHistoryRepositoryProvider = Provider<WorkoutHistoryRepository>((
  ref,
) {
  return WorkoutHistoryRepository(apiClient: ref.watch(apiClientProvider));
});

final workoutHistoryListProvider =
    FutureProvider.autoDispose<List<WorkoutHistoryEntry>>((ref) {
      return ref.watch(workoutHistoryRepositoryProvider).list();
    });

final workoutHistoryDetailProvider = FutureProvider.autoDispose
    .family<WorkoutHistoryDetail, String>((ref, id) {
      return ref.watch(workoutHistoryRepositoryProvider).getById(id);
    });
