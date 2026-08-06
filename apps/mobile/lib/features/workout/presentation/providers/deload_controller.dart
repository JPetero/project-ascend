import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/deload_repository.dart';
import '../../domain/deload_recommendation.dart';

final deloadRepositoryProvider = Provider<DeloadRepository>((ref) {
  return DeloadRepository(apiClient: ref.watch(apiClientProvider));
});

/// The user's currently-active deload recommendation, if any. Screens
/// invalidate this after dismiss/postpone so it disappears immediately.
final activeDeloadProvider = FutureProvider.autoDispose<DeloadRecommendation?>((
  ref,
) {
  return ref.watch(deloadRepositoryProvider).getActive();
});
