import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/app_database.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/workout_session_repository.dart';
import '../../domain/personal_record.dart';
import '../../domain/workout_session.dart';

final _random = Random();

String _generateLocalId() =>
    'local-${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';

class WorkoutFinishResult {
  const WorkoutFinishResult({
    required this.session,
    required this.newPersonalRecords,
    required this.synced,
  });

  final WorkoutSessionState session;
  final List<PersonalRecord> newPersonalRecords;
  final bool synced;
}

/// Owns the active (or most recently finished-but-unsynced) workout
/// session. Every mutation writes to Drift immediately so logging never
/// depends on the network — see `packages/docs/architecture.md` for the
/// synchronization strategy. Deliberately does not implement cloud
/// conflict resolution: a session either fully replays to the backend
/// (create -> log sets -> finish) when it never got a server id, or pushes
/// its not-yet-confirmed sets when it already has one. There is no merge
/// logic for edits made on two devices to the same session.
class WorkoutSessionController extends StateNotifier<WorkoutSessionState?> {
  WorkoutSessionController({
    required WorkoutSessionRepository repository,
    required AppDatabase database,
    required String userId,
  }) : _repository = repository,
       _database = database,
       _userId = userId,
       super(null) {
    _restore();
  }

  final WorkoutSessionRepository _repository;
  final AppDatabase _database;
  final String _userId;

  Future<void> _restore() async {
    final cached = await _database.readCachedWorkoutSession();
    if (cached == null) return;
    final session = WorkoutSessionState.fromCacheJson(cached);
    if (session.userId == _userId) {
      state = session;
    } else {
      // A different account signed in on this device since the cache was
      // written — never resume or show someone else's in-progress workout.
      await _database.clearCachedWorkoutSession();
    }
  }

  Future<void> _persist(WorkoutSessionState session) async {
    state = session;
    await _database.cacheWorkoutSession(session.toCacheJson());
  }

  Future<void> _clear() async {
    state = null;
    await _database.clearCachedWorkoutSession();
  }

  Future<void> start({String? workoutPlanId, String? workoutPlanName}) async {
    if (state != null && state!.isActive) {
      throw AppException(
        message: 'Finish or abandon your current workout first.',
      );
    }

    final now = DateTime.now();
    var session = WorkoutSessionState(
      localId: _generateLocalId(),
      userId: _userId,
      workoutPlanId: workoutPlanId,
      workoutPlanName: workoutPlanName,
      status: WorkoutSessionStatus.inProgress,
      startedAt: now,
      resumedAt: now,
      activeDurationSeconds: 0,
      sets: const [],
    );

    try {
      final serverSession = await _repository.start(
        workoutPlanId: workoutPlanId,
      );
      session = session.copyWith(
        serverId: serverSession['id'] as String,
        syncStatus: SessionSyncStatus.synced,
      );
    } on AppException catch (error) {
      if (error.code != 'NETWORK_ERROR') rethrow;
      session = session.copyWith(syncStatus: SessionSyncStatus.pending);
    }

    await _persist(session);
  }

  Future<void> logSet({
    required String exerciseId,
    required String exerciseName,
    int? reps,
    double? weightKg,
    int? durationSeconds,
    double? distanceMeters,
    bool isWarmup = false,
  }) async {
    final current = state;
    if (current == null || current.status != WorkoutSessionStatus.inProgress) {
      throw AppException(message: 'Resume your workout before logging a set.');
    }

    final setNumber =
        current.sets.where((s) => s.exerciseId == exerciseId).length + 1;
    var set = LoggedSet(
      localId: _generateLocalId(),
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      setNumber: setNumber,
      reps: reps,
      weightKg: weightKg,
      durationSeconds: durationSeconds,
      distanceMeters: distanceMeters,
      isWarmup: isWarmup,
      completedAt: DateTime.now(),
    );

    var session = current.copyWith(sets: [...current.sets, set]);
    await _persist(session);

    if (session.serverId == null) return;

    try {
      final serverSet = await _repository.logSet(session.serverId!, set);
      set = set.copyWith(serverId: serverSet['id'] as String);
      session = session.copyWith(
        sets: session.sets
            .map((s) => s.localId == set.localId ? set : s)
            .toList(),
      );
      await _persist(session);
    } on AppException {
      // Left unsynced; the finish()-time sync pass will push it.
    }
  }

  Future<void> pause() async {
    final current = state;
    if (current == null || current.status != WorkoutSessionStatus.inProgress) {
      return;
    }

    final now = DateTime.now();
    final elapsed = now.difference(current.resumedAt).inSeconds;
    final session = current.copyWith(
      status: WorkoutSessionStatus.paused,
      pausedAt: now,
      activeDurationSeconds:
          current.activeDurationSeconds + (elapsed < 0 ? 0 : elapsed),
    );
    await _persist(session);

    if (session.serverId != null) {
      try {
        await _repository.pause(session.serverId!);
      } on AppException {
        // Best-effort — only the final duration synced at finish() matters.
      }
    }
  }

  Future<void> resume() async {
    final current = state;
    if (current == null || current.status != WorkoutSessionStatus.paused) {
      return;
    }

    final session = current.copyWith(
      status: WorkoutSessionStatus.inProgress,
      resumedAt: DateTime.now(),
      pausedAt: null,
    );
    await _persist(session);

    if (session.serverId != null) {
      try {
        await _repository.resume(session.serverId!);
      } on AppException {
        // Best-effort, same reasoning as pause().
      }
    }
  }

  Future<WorkoutFinishResult> finish() async {
    final current = state;
    if (current == null || !current.isActive) {
      throw AppException(message: 'There is no active workout to finish.');
    }

    final now = DateTime.now();
    final additional = current.status == WorkoutSessionStatus.inProgress
        ? now.difference(current.resumedAt).inSeconds
        : 0;
    final finished = current.copyWith(
      status: WorkoutSessionStatus.completed,
      completedAt: now,
      activeDurationSeconds:
          current.activeDurationSeconds + (additional < 0 ? 0 : additional),
    );
    await _persist(finished);

    return _sync(finished, andFinish: true);
  }

  Future<void> abandon() async {
    final current = state;
    if (current == null || !current.isActive) return;

    final abandoned = current.copyWith(
      status: WorkoutSessionStatus.abandoned,
      completedAt: DateTime.now(),
    );

    if (abandoned.serverId != null) {
      try {
        await _repository.abandon(abandoned.serverId!);
      } on AppException {
        // Not retried — an abandoned workout has no data worth replaying.
      }
    }

    await _clear();
  }

  /// Re-attempts syncing a previously finished-but-unsynced session (e.g.
  /// from the Workout Summary screen's "Retry sync" action).
  Future<WorkoutFinishResult> retrySync(WorkoutSessionState session) {
    return _sync(session, andFinish: true);
  }

  Future<WorkoutFinishResult> _sync(
    WorkoutSessionState session, {
    required bool andFinish,
  }) async {
    try {
      var working = session;

      if (working.serverId == null) {
        final serverSession = await _repository.start(
          workoutPlanId: working.workoutPlanId,
        );
        working = working.copyWith(serverId: serverSession['id'] as String);
      }

      final syncedSets = <LoggedSet>[];
      for (final set in working.sets) {
        if (set.isSynced) {
          syncedSets.add(set);
          continue;
        }
        final serverSet = await _repository.logSet(working.serverId!, set);
        syncedSets.add(set.copyWith(serverId: serverSet['id'] as String));
      }
      working = working.copyWith(sets: syncedSets);

      List<PersonalRecord> newRecords = const [];
      if (andFinish) {
        final (_, records) = await _repository.finish(working.serverId!);
        newRecords = records;
      }

      working = working.copyWith(
        syncStatus: SessionSyncStatus.synced,
        syncError: null,
      );
      await _clear();

      return WorkoutFinishResult(
        session: working,
        newPersonalRecords: newRecords,
        synced: true,
      );
    } on AppException catch (error) {
      final failed = session.copyWith(
        syncStatus: SessionSyncStatus.failed,
        syncError: error.message,
      );
      await _persist(failed);
      return WorkoutFinishResult(
        session: failed,
        newPersonalRecords: const [],
        synced: false,
      );
    }
  }
}

final workoutSessionRepositoryProvider = Provider<WorkoutSessionRepository>((
  ref,
) {
  return WorkoutSessionRepository(apiClient: ref.watch(apiClientProvider));
});

final workoutSessionControllerProvider =
    StateNotifierProvider<WorkoutSessionController, WorkoutSessionState?>((
      ref,
    ) {
      final userId = ref.watch(
        authControllerProvider.select((s) => s.user?.id),
      );
      return WorkoutSessionController(
        repository: ref.watch(workoutSessionRepositoryProvider),
        database: ref.watch(appDatabaseProvider),
        userId: userId ?? '',
      );
    });
