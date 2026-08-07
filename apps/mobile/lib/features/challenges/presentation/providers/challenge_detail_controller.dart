import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/challenges_repository.dart';
import '../../domain/challenge.dart';
import 'challenges_controller.dart';

class ChallengeDetailState {
  const ChallengeDetailState({this.detail, this.isLoading = true, this.error});

  final ChallengeDetail? detail;
  final bool isLoading;
  final String? error;

  ChallengeDetailState copyWith({
    ChallengeDetail? detail,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ChallengeDetailState(
      detail: detail ?? this.detail,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChallengeDetailController extends StateNotifier<ChallengeDetailState> {
  ChallengeDetailController({
    required ChallengesRepository repository,
    required this.challengeId,
  }) : _repository = repository,
       super(const ChallengeDetailState()) {
    load();
  }

  final ChallengesRepository _repository;
  final String challengeId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final detail = await _repository.getById(challengeId);
      state = ChallengeDetailState(detail: detail, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<bool> join() async {
    try {
      await _repository.join(challengeId);
      await load();
      return true;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return false;
    }
  }

  Future<bool> leave() async {
    try {
      await _repository.leave(challengeId);
      await load();
      return true;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return false;
    }
  }

  Future<bool> delete() async {
    try {
      await _repository.delete(challengeId);
      return true;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return false;
    }
  }
}

final challengeDetailControllerProvider = StateNotifierProvider.family
    .autoDispose<ChallengeDetailController, ChallengeDetailState, String>((
      ref,
      challengeId,
    ) {
      return ChallengeDetailController(
        repository: ref.watch(challengesRepositoryProvider),
        challengeId: challengeId,
      );
    });
