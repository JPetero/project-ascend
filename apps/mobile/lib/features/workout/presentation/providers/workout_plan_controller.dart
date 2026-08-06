import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/workout_plan_repository.dart';
import '../../domain/workout_plan.dart';

final workoutPlanRepositoryProvider = Provider<WorkoutPlanRepository>((ref) {
  return WorkoutPlanRepository(apiClient: ref.watch(apiClientProvider));
});

final workoutPlanDetailProvider = FutureProvider.autoDispose
    .family<WorkoutPlan, String>((ref, id) {
      return ref.watch(workoutPlanRepositoryProvider).getById(id);
    });
