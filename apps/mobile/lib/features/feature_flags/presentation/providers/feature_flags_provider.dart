import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/feature_flags_repository.dart';

final featureFlagsRepositoryProvider = Provider<FeatureFlagsRepository>((ref) {
  return FeatureFlagsRepository(apiClient: ref.watch(apiClientProvider));
});

/// Resolved once per sign-in (Build Session 12 Part 15-17). Fail-open by
/// design: every caller reads a flag as `flags['some_key'] ?? true`, so a
/// key that's absent — including while this is still loading, the user
/// is signed out, or the fetch failed — is treated as enabled, never as
/// disabled. See FeatureFlag's schema doc comment (services/api) for the
/// same contract server-side.
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
