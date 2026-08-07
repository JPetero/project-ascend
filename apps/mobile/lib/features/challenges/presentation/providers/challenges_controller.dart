import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/challenges_repository.dart';
import '../../domain/challenge.dart';

final challengesRepositoryProvider = Provider<ChallengesRepository>((ref) {
  return ChallengesRepository(apiClient: ref.watch(apiClientProvider));
});

class ChallengesState {
  const ChallengesState({
    this.mine = const [],
    this.discoverable = const [],
    this.isLoading = true,
    this.error,
  });

  final List<Challenge> mine;
  final List<Challenge> discoverable;
  final bool isLoading;
  final String? error;

  ChallengesState copyWith({
    List<Challenge>? mine,
    List<Challenge>? discoverable,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ChallengesState(
      mine: mine ?? this.mine,
      discoverable: discoverable ?? this.discoverable,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// The caller's joined challenges plus discoverable ones they haven't
/// joined yet — the two lists a Challenges home screen needs, same
/// mine/discover split as Trainer Groups' invitations.
class ChallengesController extends StateNotifier<ChallengesState> {
  ChallengesController({required ChallengesRepository repository})
    : _repository = repository,
      super(const ChallengesState()) {
    refresh();
  }

  final ChallengesRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _repository.listMine(),
        _repository.listDiscoverable(),
      ]);
      state = ChallengesState(
        mine: results[0],
        discoverable: results[1],
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<bool> join(String id) async {
    try {
      await _repository.join(id);
      await refresh();
      return true;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return false;
    }
  }
}

final challengesControllerProvider =
    StateNotifierProvider<ChallengesController, ChallengesState>((ref) {
      return ChallengesController(
        repository: ref.watch(challengesRepositoryProvider),
      );
    });
