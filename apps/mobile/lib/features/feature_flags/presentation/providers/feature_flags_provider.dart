import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/feature_flags_repository.dart';
import '../../domain/ascend_feature.dart';

final featureFlagsRepositoryProvider = Provider<FeatureFlagsRepository>((ref) {
  return FeatureFlagsRepository(apiClient: ref.watch(apiClientProvider));
});

/// Resolved once per sign-in. Returns `{}` while signed out, still
/// loading, or on a network failure — callers should never read this map
/// directly by a raw string key (that was Build Session 12's blanket
/// "absent = enabled" contract, replaced in Build Session 13 Part 1).
/// Use [featureEnabledProvider] instead, which applies the same
/// per-flag registry default services/api's `FeatureFlagsService`
/// applies server-side, rather than a single blanket fallback.
final featureFlagsProvider = FutureProvider<Map<String, bool>>((ref) async {
  final user = ref.watch(authControllerProvider.select((state) => state.user));
  if (user == null) return {};

  final repository = ref.watch(featureFlagsRepositoryProvider);
  try {
    return await repository.resolve();
  } catch (_) {
    return {};
  }
});

/// The one supported way to read a feature flag — Build Session 13 Part
/// 1. Reads the resolved map when it's available; while loading, on a
/// network failure, or for the (should-never-happen-once-resolved, but
/// defended) case of a registered key missing from the response, falls
/// back to that flag's own [AscendFeatureWireKey.registryDefault] rather
/// than a single blanket value — so a risky/external/Premium feature
/// (e.g. [AscendFeature.liveAi]) can never come back on merely because
/// this hasn't resolved yet, while a safe core feature
/// (e.g. [AscendFeature.trainerDashboard]) doesn't flicker off during
/// the brief window before the first resolution completes.
final featureEnabledProvider = Provider.family<bool, AscendFeature>((
  ref,
  feature,
) {
  final resolved = ref.watch(featureFlagsProvider).asData?.value;
  if (resolved == null) return feature.registryDefault;
  return resolved[feature.key] ?? feature.registryDefault;
});
