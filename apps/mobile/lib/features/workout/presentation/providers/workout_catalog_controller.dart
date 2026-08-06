import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/workout_catalog_repository.dart';
import '../../domain/workout.dart';

final workoutCatalogRepositoryProvider = Provider<WorkoutCatalogRepository>((
  ref,
) {
  return WorkoutCatalogRepository(apiClient: ref.watch(apiClientProvider));
});

final workoutCatalogListProvider = FutureProvider.autoDispose<List<Workout>>((
  ref,
) {
  return ref.watch(workoutCatalogRepositoryProvider).list();
});

final workoutCatalogDetailProvider = FutureProvider.autoDispose
    .family<Workout, String>((ref, id) {
      return ref.watch(workoutCatalogRepositoryProvider).getById(id);
    });
