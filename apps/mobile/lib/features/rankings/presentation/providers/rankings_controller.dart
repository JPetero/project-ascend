import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/rankings_repository.dart';
import '../../domain/ranking.dart';

final rankingsRepositoryProvider = Provider<RankingsRepository>((ref) {
  return RankingsRepository(apiClient: ref.watch(apiClientProvider));
});

class RankingsState {
  const RankingsState({
    this.status = const RankingMyStatus(optedIn: false),
    this.selectedScope = RankingScope.global,
    this.selectedCategory = RankingCategory.overall,
    this.leaderboard = const [],
    this.isLoading = true,
    this.isLeaderboardLoading = false,
    this.error,
  });

  final RankingMyStatus status;
  final RankingScope selectedScope;
  final RankingCategory selectedCategory;
  final List<LeaderboardEntry> leaderboard;
  final bool isLoading;
  final bool isLeaderboardLoading;
  final String? error;

  RankingsState copyWith({
    RankingMyStatus? status,
    RankingScope? selectedScope,
    RankingCategory? selectedCategory,
    List<LeaderboardEntry>? leaderboard,
    bool? isLoading,
    bool? isLeaderboardLoading,
    String? error,
    bool clearError = false,
  }) {
    return RankingsState(
      status: status ?? this.status,
      selectedScope: selectedScope ?? this.selectedScope,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      leaderboard: leaderboard ?? this.leaderboard,
      isLoading: isLoading ?? this.isLoading,
      isLeaderboardLoading: isLeaderboardLoading ?? this.isLeaderboardLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Own opt-in status plus the currently-selected scope's leaderboard —
/// see packages/docs/product/user-scenario-bible.md Scenario 16a. Off by
/// default: until [RankingMyStatus.optedIn] is true, no leaderboard is
/// ever fetched.
class RankingsController extends StateNotifier<RankingsState> {
  RankingsController({required RankingsRepository repository})
    : _repository = repository,
      super(const RankingsState()) {
    refresh();
  }

  final RankingsRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final status = await _repository.getMyStatus();
      state = state.copyWith(
        status: status,
        selectedScope: status.scope ?? state.selectedScope,
        isLoading: false,
      );
      if (status.optedIn) {
        await _loadLeaderboard(state.selectedScope, state.selectedCategory);
      }
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> selectScope(RankingScope scope) async {
    state = state.copyWith(selectedScope: scope);
    await _loadLeaderboard(scope, state.selectedCategory);
  }

  Future<void> selectCategory(RankingCategory category) async {
    state = state.copyWith(selectedCategory: category);
    await _loadLeaderboard(state.selectedScope, category);
  }

  Future<void> _loadLeaderboard(
    RankingScope scope,
    RankingCategory category,
  ) async {
    state = state.copyWith(isLeaderboardLoading: true, clearError: true);
    try {
      final page = await _repository.getLeaderboard(
        scope: scope,
        category: category,
      );
      state = state.copyWith(
        leaderboard: page.entries,
        isLeaderboardLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        leaderboard: const [],
        isLeaderboardLoading: false,
        error: error.toString(),
      );
    }
  }

  Future<bool> optIn({
    required RankingScope scope,
    String? localityCountry,
    String? localityRegion,
    String? localityCity,
    String? localityArea,
  }) async {
    try {
      await _repository.optIn(
        scope: scope,
        localityCountry: localityCountry,
        localityRegion: localityRegion,
        localityCity: localityCity,
        localityArea: localityArea,
      );
      await refresh();
      return true;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return false;
    }
  }

  Future<void> optOut() async {
    try {
      await _repository.optOut();
      await refresh();
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }
}

final rankingsControllerProvider =
    StateNotifierProvider<RankingsController, RankingsState>((ref) {
      return RankingsController(
        repository: ref.watch(rankingsRepositoryProvider),
      );
    });
