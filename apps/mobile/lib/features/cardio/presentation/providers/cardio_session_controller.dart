import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/cardio_session_repository.dart';
import '../../domain/cardio_session.dart';

final cardioSessionRepositoryProvider = Provider<CardioSessionRepository>((
  ref,
) {
  return CardioSessionRepository(apiClient: ref.watch(apiClientProvider));
});

/// The user's cardio session history, most recent first. Screens
/// invalidate this after logging or deleting a session.
final cardioSessionsProvider = FutureProvider.autoDispose<List<CardioSession>>((
  ref,
) {
  return ref.watch(cardioSessionRepositoryProvider).list();
});
