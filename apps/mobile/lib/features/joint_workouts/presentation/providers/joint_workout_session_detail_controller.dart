import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/joint_workout_sessions_repository.dart';
import '../../domain/joint_workout_session.dart';
import 'joint_workout_sessions_controller.dart';

class JointWorkoutSessionDetailState {
  const JointWorkoutSessionDetailState({
    this.session,
    this.isLoading = true,
    this.isActing = false,
    this.error,
  });

  final JointWorkoutSession? session;
  final bool isLoading;
  final bool isActing;
  final String? error;

  JointWorkoutSessionDetailState copyWith({
    JointWorkoutSession? session,
    bool? isLoading,
    bool? isActing,
    String? error,
  }) {
    return JointWorkoutSessionDetailState(
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      isActing: isActing ?? this.isActing,
      error: error,
    );
  }
}

/// Drives one joint workout session's full lifecycle — Build Session 8
/// Part 9: invite/accept/decline/ready/start/progress/finish/leave/
/// cancel, matching JointWorkoutSessionsService on the backend exactly.
class JointWorkoutSessionDetailController
    extends StateNotifier<JointWorkoutSessionDetailState> {
  JointWorkoutSessionDetailController({
    required JointWorkoutSessionsRepository repository,
    required this.sessionId,
  }) : _repository = repository,
       super(const JointWorkoutSessionDetailState()) {
    load();
  }

  final JointWorkoutSessionsRepository _repository;
  final String sessionId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final session = await _repository.getById(sessionId);
      state = JointWorkoutSessionDetailState(
        session: session,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<bool> _act(Future<void> Function() action) async {
    state = state.copyWith(isActing: true, error: null);
    try {
      await action();
      await load();
      return true;
    } catch (error) {
      state = state.copyWith(isActing: false, error: error.toString());
      return false;
    }
  }

  Future<bool> invite(String inviteeId) =>
      _act(() => _repository.invite(sessionId, inviteeId));

  Future<bool> accept() => _act(() => _repository.accept(sessionId));

  Future<bool> decline() => _act(() => _repository.decline(sessionId));

  Future<bool> markReady() => _act(() => _repository.ready(sessionId));

  Future<bool> start() => _act(() => _repository.start(sessionId));

  Future<bool> submitProgress({
    String? exerciseName,
    int? setsCompleted,
    int? durationSeconds,
    double? distanceMeters,
    bool? isPersonalRecord,
  }) => _act(
    () => _repository.submitProgress(
      sessionId,
      exerciseName: exerciseName,
      setsCompleted: setsCompleted,
      durationSeconds: durationSeconds,
      distanceMeters: distanceMeters,
      isPersonalRecord: isPersonalRecord,
    ),
  );

  Future<bool> finish() => _act(() => _repository.finish(sessionId));

  Future<bool> leave() => _act(() => _repository.leave(sessionId));

  Future<bool> cancel() => _act(() => _repository.cancel(sessionId));
}

final jointWorkoutSessionDetailControllerProvider = StateNotifierProvider
    .autoDispose
    .family<
      JointWorkoutSessionDetailController,
      JointWorkoutSessionDetailState,
      String
    >((ref, sessionId) {
      return JointWorkoutSessionDetailController(
        repository: ref.watch(jointWorkoutSessionsRepositoryProvider),
        sessionId: sessionId,
      );
    });
