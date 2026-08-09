import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/companion_memory_repository.dart';

final companionMemoryRepositoryProvider = Provider<CompanionMemoryRepository>((
  ref,
) {
  return CompanionMemoryRepository(apiClient: ref.watch(apiClientProvider));
});

class CompanionMemoryState {
  const CompanionMemoryState({
    this.notes = const [],
    this.isLoading = true,
    this.error,
  });

  final List<String> notes;
  final bool isLoading;
  final String? error;

  CompanionMemoryState copyWith({
    List<String>? notes,
    bool? isLoading,
    String? error,
  }) {
    return CompanionMemoryState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Backs the "manage memory" screen reachable from the "AI memory"
/// toggle in dashboard_screen.dart (Build Session 10 Part 15) — a real,
/// inspectable view of what Atlas/Nova remembers, and a real clear
/// action, rather than invisible state.
class CompanionMemoryController extends StateNotifier<CompanionMemoryState> {
  CompanionMemoryController({required CompanionMemoryRepository repository})
    : _repository = repository,
      super(const CompanionMemoryState()) {
    refresh();
  }

  final CompanionMemoryRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final notes = await _repository.fetchNotes();
      state = CompanionMemoryState(notes: notes, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> clear() async {
    await _repository.clear();
    state = state.copyWith(notes: const []);
  }
}

final companionMemoryControllerProvider =
    StateNotifierProvider<CompanionMemoryController, CompanionMemoryState>((
      ref,
    ) {
      return CompanionMemoryController(
        repository: ref.watch(companionMemoryRepositoryProvider),
      );
    });
