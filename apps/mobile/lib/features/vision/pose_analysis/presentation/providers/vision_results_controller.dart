import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/core_providers.dart';
import '../../data/vision_results_repository.dart';
import '../../domain/vision_analysis_session.dart';

final visionResultsRepositoryProvider = Provider<VisionResultsRepository>((
  ref,
) {
  return VisionResultsRepository(apiClient: ref.watch(apiClientProvider));
});

enum VisionResultsStatus { loading, loaded, error }

class VisionResultsState {
  const VisionResultsState({
    this.status = VisionResultsStatus.loading,
    this.sessions = const [],
    this.errorMessage,
  });

  final VisionResultsStatus status;
  final List<VisionAnalysisSession> sessions;
  final String? errorMessage;

  VisionResultsState copyWith({
    VisionResultsStatus? status,
    List<VisionAnalysisSession>? sessions,
    String? errorMessage,
  }) {
    return VisionResultsState(
      status: status ?? this.status,
      sessions: sessions ?? this.sessions,
      errorMessage: errorMessage,
    );
  }
}

/// Drives the Vision result history list (Build Session 10 Part 6) —
/// loads a Premium user's own saved sessions and lets them delete one.
/// Deletion is optimistic-free: the list only drops an entry after the
/// server confirms it, so a failed delete never silently hides a row
/// that's still actually saved.
class VisionResultsController extends StateNotifier<VisionResultsState> {
  VisionResultsController({required VisionResultsRepository repository})
    : _repository = repository,
      super(const VisionResultsState()) {
    load();
  }

  final VisionResultsRepository _repository;

  Future<void> load() async {
    state = state.copyWith(status: VisionResultsStatus.loading);
    try {
      final sessions = await _repository.listSessions();
      state = state.copyWith(
        status: VisionResultsStatus.loaded,
        sessions: sessions,
      );
    } catch (error) {
      state = state.copyWith(
        status: VisionResultsStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> delete(String id) async {
    await _repository.deleteSession(id);
    state = state.copyWith(
      sessions: state.sessions.where((s) => s.id != id).toList(),
    );
  }
}

final visionResultsControllerProvider =
    StateNotifierProvider.autoDispose<
      VisionResultsController,
      VisionResultsState
    >((ref) {
      return VisionResultsController(
        repository: ref.watch(visionResultsRepositoryProvider),
      );
    });
