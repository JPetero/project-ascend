import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/macro_target_repository.dart';
import '../../domain/macro_target.dart';

final macroTargetRepositoryProvider = Provider<MacroTargetRepository>((ref) {
  return MacroTargetRepository(apiClient: ref.watch(apiClientProvider));
});

/// The user's current macro targets. The macro target editor screen
/// invalidates this after a successful save so the Meal Prep dashboard's
/// numbers reflect the change immediately.
final macroTargetProvider = FutureProvider.autoDispose<MacroTarget>((ref) {
  return ref.watch(macroTargetRepositoryProvider).get();
});
