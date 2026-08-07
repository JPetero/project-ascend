import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/sports_repository.dart';
import '../../domain/sport_match.dart';

final sportsRepositoryProvider = Provider<SportsRepository>((ref) {
  return SportsRepository(apiClient: ref.watch(apiClientProvider));
});

class SportsMatchesState {
  const SportsMatchesState({
    this.matches = const [],
    this.rating,
    this.isLoading = true,
    this.error,
  });

  final List<SportMatch> matches;
  final SportRating? rating;
  final bool isLoading;
  final String? error;

  SportsMatchesState copyWith({
    List<SportMatch>? matches,
    SportRating? rating,
    bool? isLoading,
    String? error,
  }) {
    return SportsMatchesState(
      matches: matches ?? this.matches,
      rating: rating ?? this.rating,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// The caller's sports matches plus their Badminton rating — Build
/// Session 8 Part 10.
class SportsMatchesController extends StateNotifier<SportsMatchesState> {
  SportsMatchesController({required SportsRepository repository})
    : _repository = repository,
      super(const SportsMatchesState()) {
    refresh();
  }

  final SportsRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _repository.listMine(),
        _repository.getMyRating(),
      ]);
      state = SportsMatchesState(
        matches: results[0] as List<SportMatch>,
        rating: results[1] as SportRating,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<SportMatch?> createMatch(String opponentId) async {
    try {
      final match = await _repository.createMatch(opponentId: opponentId);
      await refresh();
      return match;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return null;
    }
  }
}

final sportsMatchesControllerProvider =
    StateNotifierProvider<SportsMatchesController, SportsMatchesState>((ref) {
      return SportsMatchesController(
        repository: ref.watch(sportsRepositoryProvider),
      );
    });
