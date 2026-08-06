import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/app_database.dart';
import '../../../../core/sync/idempotency_key.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/sync/sync_handler.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/workout_session_repository.dart';
import '../../domain/exercise_substitution.dart';
import '../../domain/personal_record.dart';
import '../../domain/workout_session.dart';

String _generateLocalId() => generateIdempotencyKey('local');

const _substitutionEntityType = 'workout.substitution';

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
    required SyncEngine syncEngine,
    required String userId,
  }) : _repository = repository,
       _database = database,
       _syncEngine = syncEngine,
       _userId = userId,
       super(null) {
    _syncEngine.registerHandler(
      _substitutionEntityType,
      FunctionSyncHandler(({required payload, required idempotencyKey}) async {
        final result = await _repository.substituteExercise(
          payload['sessionId'] as String,
          originalExerciseId: payload['originalExerciseId'] as String,
          substituteExerciseId: payload['substituteExerciseId'] as String,
          idempotencyKey: idempotencyKey,
        );
        return SyncHandlerResult(
          entityId: result['id'] as String?,
          response: result,
        );
      }),
    );
    _restore();
  }

  final WorkoutSessionRepository _repository;
  final AppDatabase _database;
  final SyncEngine _syncEngine;
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
        idempotencyKey: session.localId,
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

  /// Applies an exercise substitution for the remainder of the session.
  /// Already-logged sets under [originalExerciseId] are untouched — only
  /// [logSet] calls made *after* this resolve to [substituteExerciseId].
  /// Local-first like every other mutation here: the swap is visible in the
  /// player immediately, and syncs via the generic [SyncEngine] (when the
  /// session already has a server id) or the next full [_sync] pass
  /// (when it doesn't yet — e.g. a session started fully offline).
  Future<void> substituteExercise({
    required String originalExerciseId,
    required String originalExerciseName,
    required String substituteExerciseId,
    required String substituteExerciseName,
  }) async {
    final current = state;
    if (current == null || !current.isActive) {
      throw AppException(message: 'There is no active workout to modify.');
    }

    final substitution = ExerciseSubstitution(
      localId: generateIdempotencyKey('sub'),
      originalExerciseId: originalExerciseId,
      originalExerciseName: originalExerciseName,
      substituteExerciseId: substituteExerciseId,
      substituteExerciseName: substituteExerciseName,
    );

    final session = current.copyWith(
      substitutions: [...current.substitutions, substitution],
    );
    await _persist(session);

    if (session.serverId == null) return;

    await _syncEngine.enqueue(
      idempotencyKey: substitution.localId,
      entityType: _substitutionEntityType,
      operationType: 'CREATE',
      payload: {
        'sessionId': session.serverId,
        'originalExerciseId': originalExerciseId,
        'substituteExerciseId': substituteExerciseId,
      },
    );
  }

  Future<void> logSet({
    required String exerciseId,
    required String exerciseName,
    int? reps,
    double? weightKg,
    int? durationSeconds,
    double? distanceMeters,
    bool isWarmup = false,
    double? rpe,
  }) async {
    final current = state;
    if (current == null || current.status != WorkoutSessionStatus.inProgress) {
      throw AppException(message: 'Resume your workout before logging a set.');
    }

    final substitution = current.activeSubstitutionFor(exerciseId);
    final effectiveExerciseId = substitution?.substituteExerciseId ?? exerciseId;
    final effectiveExerciseName =
        substitution?.substituteExerciseName ?? exerciseName;

    final setNumber =
        current.sets.where((s) => s.exerciseId == effectiveExerciseId).length +
        1;
    var set = LoggedSet(
      localId: _generateLocalId(),
      exerciseId: effectiveExerciseId,
      exerciseName: effectiveExerciseName,
      setNumber: setNumber,
      reps: reps,
      weightKg: weightKg,
      durationSeconds: durationSeconds,
      distanceMeters: distanceMeters,
      isWarmup: isWarmup,
      completedAt: DateTime.now(),
      rpe: rpe,
    );

    var session = current.copyWith(sets: [...current.sets, set]);
    await _persist(session);

    if (session.serverId == null) return;

    try {
      final serverSet = await _repository.logSet(
        session.serverId!,
        set,
        idempotencyKey: set.localId,
      );
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

  Future<WorkoutFinishResult> finish({int? difficultyRating}) async {
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
      difficultyRating: difficultyRating,
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
          idempotencyKey: working.localId,
        );
        working = working.copyWith(serverId: serverSession['id'] as String);
      }

      // Substitutions before sets: cosmetically keeps the history record's
      // ordering matching what actually happened, though correctness
      // doesn't depend on it — each set already carries its own resolved
      // exercise id from the moment it was logged (see `logSet`).
      final syncedSubstitutions = <ExerciseSubstitution>[];
      for (final substitution in working.substitutions) {
        if (substitution.isSynced) {
          syncedSubstitutions.add(substitution);
          continue;
        }
        // Reuses the same idempotency key regardless of whether the
        // generic SyncEngine already delivered this substitution
        // successfully elsewhere — the backend just replays the same
        // result, so a redundant call here is safe, not a duplicate.
        final serverSubstitution = await _repository.substituteExercise(
          working.serverId!,
          originalExerciseId: substitution.originalExerciseId,
          substituteExerciseId: substitution.substituteExerciseId,
          idempotencyKey: substitution.localId,
        );
        syncedSubstitutions.add(
          substitution.copyWith(serverId: serverSubstitution['id'] as String),
        );
      }
      working = working.copyWith(substitutions: syncedSubstitutions);

      final syncedSets = <LoggedSet>[];
      for (final set in working.sets) {
        if (set.isSynced) {
          syncedSets.add(set);
          continue;
        }
        final serverSet = await _repository.logSet(
          working.serverId!,
          set,
          idempotencyKey: set.localId,
        );
        syncedSets.add(set.copyWith(serverId: serverSet['id'] as String));
      }
      working = working.copyWith(sets: syncedSets);

      List<PersonalRecord> newRecords = const [];
      if (andFinish) {
        final (_, records) = await _repository.finish(
          working.serverId!,
          difficultyRating: working.difficultyRating,
        );
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
        syncEngine: ref.watch(syncEngineProvider),
        userId: userId ?? '',
      );
    });
