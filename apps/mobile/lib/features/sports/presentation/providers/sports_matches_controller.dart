import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../rankings/domain/ranking.dart';
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
    this.leaderboard = const [],
    this.leaderboardScope = RankingScope.global,
    this.isLoading = true,
    this.isLeaderboardLoading = false,
    this.error,
    this.leaderboardError,
  });

  final List<SportMatch> matches;
  final List<SportSummary> sports;
  final String selectedSportCode;
  final SportRating? rating;
  final List<SportLeaderboardEntry> leaderboard;
  final RankingScope leaderboardScope;
  final bool isLoading;
  final bool isLeaderboardLoading;
  final String? error;
  final String? leaderboardError;

  SportsMatchesState copyWith({
    List<SportMatch>? matches,
    List<SportSummary>? sports,
    String? selectedSportCode,
    SportRating? rating,
    List<SportLeaderboardEntry>? leaderboard,
    RankingScope? leaderboardScope,
    bool? isLoading,
    bool? isLeaderboardLoading,
    String? error,
    String? leaderboardError,
    bool clearError = false,
    bool clearLeaderboardError = false,
  }) {
    return SportsMatchesState(
      matches: matches ?? this.matches,
      sports: sports ?? this.sports,
      selectedSportCode: selectedSportCode ?? this.selectedSportCode,
      rating: rating ?? this.rating,
      leaderboard: leaderboard ?? this.leaderboard,
      leaderboardScope: leaderboardScope ?? this.leaderboardScope,
      isLoading: isLoading ?? this.isLoading,
      isLeaderboardLoading: isLeaderboardLoading ?? this.isLeaderboardLoading,
      error: clearError ? null : (error ?? this.error),
      leaderboardError: clearLeaderboardError
          ? null
          : (leaderboardError ?? this.leaderboardError),
    );
  }
}

/// The caller's sports matches, their rating, and a scoped leaderboard
/// for the selected sport — Build Session 8 Part 10, generalized to more
/// than one sport in Build Session 12 Part 23-24, and given the same
/// FRIENDS/LOCAL/CITY/REGION/NATIONAL/GLOBAL scoping Rankings has in
/// Build Session 13 continuation Part E (reusing RankingsRepository's
/// exact scope vocabulary — see services/api/src/common/rankings).
class SportsMatchesController extends StateNotifier<SportsMatchesState> {
  SportsMatchesController({required SportsRepository repository})
    : _repository = repository,
      super(const SportsMatchesState()) {
    refresh();
  }

  final SportsRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
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
        clearError: true,
      );
      await _loadLeaderboard();
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> selectSport(String sportCode) async {
    if (sportCode == state.selectedSportCode) return;
    state = state.copyWith(selectedSportCode: sportCode, isLoading: true);
    try {
      final rating = await _repository.getMyRating(sportCode: sportCode);
      state = state.copyWith(
        rating: rating,
        isLoading: false,
        clearError: true,
      );
      await _loadLeaderboard();
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> selectLeaderboardScope(RankingScope scope) async {
    state = state.copyWith(leaderboardScope: scope);
    await _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    state = state.copyWith(
      isLeaderboardLoading: true,
      clearLeaderboardError: true,
    );
    try {
      final leaderboard = await _repository.leaderboard(
        sportCode: state.selectedSportCode,
        scope: state.leaderboardScope,
      );
      state = state.copyWith(
        leaderboard: leaderboard,
        isLeaderboardLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        leaderboard: const [],
        isLeaderboardLoading: false,
        leaderboardError: error.toString(),
      );
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
