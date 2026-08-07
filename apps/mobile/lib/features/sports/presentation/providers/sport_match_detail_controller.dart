import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sports_repository.dart';
import '../../domain/sport_match.dart';
import 'sports_matches_controller.dart';

class SportMatchDetailState {
  const SportMatchDetailState({
    this.match,
    this.isLoading = true,
    this.isActing = false,
    this.error,
  });

  final SportMatch? match;
  final bool isLoading;
  final bool isActing;
  final String? error;

  SportMatchDetailState copyWith({
    SportMatch? match,
    bool? isLoading,
    bool? isActing,
    String? error,
  }) {
    return SportMatchDetailState(
      match: match ?? this.match,
      isLoading: isLoading ?? this.isLoading,
      isActing: isActing ?? this.isActing,
      error: error,
    );
  }
}

/// Drives one sports match's full lifecycle — Build Session 8 Part 10:
/// accept/decline/ready/start/score-proposal/confirm/dispute/cancel/
/// void, matching SportsService on the backend exactly.
class SportMatchDetailController extends StateNotifier<SportMatchDetailState> {
  SportMatchDetailController({
    required SportsRepository repository,
    required this.matchId,
  }) : _repository = repository,
       super(const SportMatchDetailState()) {
    load();
  }

  final SportsRepository _repository;
  final String matchId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final match = await _repository.getById(matchId);
      state = SportMatchDetailState(match: match, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<bool> _act(Future<SportMatch> Function() action) async {
    state = state.copyWith(isActing: true, error: null);
    try {
      final match = await action();
      state = state.copyWith(match: match, isActing: false);
      return true;
    } catch (error) {
      state = state.copyWith(isActing: false, error: error.toString());
      return false;
    }
  }

  Future<bool> accept() => _act(() => _repository.accept(matchId));

  Future<bool> decline() => _act(() => _repository.decline(matchId));

  Future<bool> markReady() => _act(() => _repository.ready(matchId));

  Future<bool> start() => _act(() => _repository.start(matchId));

  Future<bool> proposeScore(int proposerScore, int opponentScore) => _act(
    () => _repository.proposeScore(
      matchId,
      proposerScore: proposerScore,
      opponentScore: opponentScore,
    ),
  );

  Future<bool> confirmScore() => _act(() => _repository.confirmScore(matchId));

  Future<bool> disputeScore(String reason) =>
      _act(() => _repository.disputeScore(matchId, reason));

  Future<bool> cancel() => _act(() => _repository.cancel(matchId));

  Future<bool> voidMatch() => _act(() => _repository.voidMatch(matchId));
}

final sportMatchDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<SportMatchDetailController, SportMatchDetailState, String>((
      ref,
      matchId,
    ) {
      return SportMatchDetailController(
        repository: ref.watch(sportsRepositoryProvider),
        matchId: matchId,
      );
    });
