import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/trainer_group.dart';
import 'trainer_groups_controller.dart';

/// The trainer dashboard (Build Session 12 Part 11) — a read-only
/// aggregate across every group the caller owns or moderates.
/// `.autoDispose` since a viewer only cares about it while the
/// dashboard screen is open.
final trainerDashboardProvider = FutureProvider.autoDispose<TrainerDashboard>((
  ref,
) {
  return ref.watch(trainerGroupsRepositoryProvider).getTrainerDashboard();
});
