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
    this.sports = const [],
    this.selectedSportCode = SportsRepository.badmintonCode,
    this.rating,
    this.isLoading = true,
    this.error,
  });

  final List<SportMatch> matches;
  final List<SportSummary> sports;
  final String selectedSportCode;
  final SportRating? rating;
  final bool isLoading;
  final String? error;

  SportsMatchesState copyWith({
    List<SportMatch>? matches,
    List<SportSummary>? sports,
    String? selectedSportCode,
    SportRating? rating,
    bool? isLoading,
    String? error,
  }) {
    return SportsMatchesState(
      matches: matches ?? this.matches,
      sports: sports ?? this.sports,
      selectedSportCode: selectedSportCode ?? this.selectedSportCode,
      rating: rating ?? this.rating,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// The caller's sports matches plus their rating for the selected sport
/// — Build Session 8 Part 10, generalized to more than one sport in
/// Build Session 12 Part 23-24.
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
        _repository.listSports(),
        _repository.getMyRating(sportCode: state.selectedSportCode),
      ]);
      state = state.copyWith(
        matches: results[0] as List<SportMatch>,
        sports: results[1] as List<SportSummary>,
        rating: results[2] as SportRating,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> selectSport(String sportCode) async {
    if (sportCode == state.selectedSportCode) return;
    state = state.copyWith(selectedSportCode: sportCode, isLoading: true);
    try {
      final rating = await _repository.getMyRating(sportCode: sportCode);
      state = state.copyWith(rating: rating, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<SportMatch?> createMatch(
    String opponentId, {
    String sportCode = SportsRepository.badmintonCode,
  }) async {
    try {
      final match = await _repository.createMatch(
        opponentId: opponentId,
        sportCode: sportCode,
      );
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
