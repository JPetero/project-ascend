import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/trainer_verification_repository.dart';
import '../../domain/trainer_verification_status.dart';

final trainerVerificationRepositoryProvider =
    Provider<TrainerVerificationRepository>((ref) {
      return TrainerVerificationRepository(
        apiClient: ref.watch(apiClientProvider),
      );
    });

class TrainerVerificationState {
  const TrainerVerificationState({
    this.status,
    this.isLoading = true,
    this.isApplying = false,
    this.error,
  });

  final TrainerVerificationApplicationStatus? status;
  final bool isLoading;
  final bool isApplying;
  final String? error;

  TrainerVerificationState copyWith({
    TrainerVerificationApplicationStatus? status,
    bool? isLoading,
    bool? isApplying,
    String? error,
    bool clearError = false,
  }) {
    return TrainerVerificationState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      isApplying: isApplying ?? this.isApplying,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Backs the Trainer Verification screen — the caller's own application
/// status and the apply flow. Build Session 12 Part 25-26.
class TrainerVerificationController
    extends StateNotifier<TrainerVerificationState> {
  TrainerVerificationController({
    required TrainerVerificationRepository repository,
  }) : _repository = repository,
       super(const TrainerVerificationState()) {
    refresh();
  }

  final TrainerVerificationRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final status = await _repository.getMyStatus();
      state = TrainerVerificationState(status: status, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<bool> apply({required String credentials}) async {
    state = state.copyWith(isApplying: true, clearError: true);
    try {
      final status = await _repository.apply(credentials: credentials);
      state = state.copyWith(status: status, isApplying: false);
      return true;
    } catch (error) {
      state = state.copyWith(isApplying: false, error: error.toString());
      return false;
    }
  }
}

final trainerVerificationControllerProvider =
    StateNotifierProvider<
      TrainerVerificationController,
      TrainerVerificationState
    >((ref) {
      return TrainerVerificationController(
        repository: ref.watch(trainerVerificationRepositoryProvider),
      );
    });
