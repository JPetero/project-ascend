import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/joint_workout_sessions_repository.dart';
import '../../domain/joint_workout_session.dart';

final jointWorkoutSessionsRepositoryProvider =
    Provider<JointWorkoutSessionsRepository>((ref) {
      return JointWorkoutSessionsRepository(
        apiClient: ref.watch(apiClientProvider),
      );
    });

class JointWorkoutSessionsState {
  const JointWorkoutSessionsState({
    this.sessions = const [],
    this.isLoading = true,
    this.error,
  });

  final List<JointWorkoutSession> sessions;
  final bool isLoading;
  final String? error;

  JointWorkoutSessionsState copyWith({
    List<JointWorkoutSession>? sessions,
    bool? isLoading,
    String? error,
  }) {
    return JointWorkoutSessionsState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// The caller's joint workout sessions, hosted or joined — Build Session
/// 8 Part 9.
class JointWorkoutSessionsController
    extends StateNotifier<JointWorkoutSessionsState> {
  JointWorkoutSessionsController({
    required JointWorkoutSessionsRepository repository,
  }) : _repository = repository,
       super(const JointWorkoutSessionsState()) {
    refresh();
  }

  final JointWorkoutSessionsRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sessions = await _repository.listMine();
      state = JointWorkoutSessionsState(sessions: sessions, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<JointWorkoutSession?> create({
    String? title,
    List<String>? inviteeIds,
    String? trainerGroupId,
  }) async {
    try {
      final session = await _repository.create(
        title: title,
        inviteeIds: inviteeIds,
        trainerGroupId: trainerGroupId,
      );
      await refresh();
      return session;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return null;
    }
  }
}

final jointWorkoutSessionsControllerProvider =
    StateNotifierProvider<
      JointWorkoutSessionsController,
      JointWorkoutSessionsState
    >((ref) {
      return JointWorkoutSessionsController(
        repository: ref.watch(jointWorkoutSessionsRepositoryProvider),
      );
    });
