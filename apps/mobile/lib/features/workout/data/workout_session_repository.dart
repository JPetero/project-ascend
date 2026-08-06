import '../../../core/networking/api_client.dart';
import '../domain/personal_record.dart';
import '../domain/workout_session.dart';

/// The raw backend calls behind a workout session. Deliberately thin and
/// stateless — all offline/local-first behavior (deciding *when* to call
/// these, and what to do if a call fails) lives in
/// `WorkoutSessionController`, not here.
class WorkoutSessionRepository {
  WorkoutSessionRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> start({
    String? workoutPlanId,
    String? idempotencyKey,
  }) async {
    final envelope = await _apiClient.post(
      '/workout-sessions',
      (data) => data as Map<String, dynamic>,
      data: {
        'workoutPlanId': ?workoutPlanId,
        'idempotencyKey': ?idempotencyKey,
      },
    );
    return envelope.data!;
  }

  Future<Map<String, dynamic>?> getActive() async {
    final envelope = await _apiClient.get(
      '/workout-sessions/active',
      (data) => data as Map<String, dynamic>?,
    );
    return envelope.data;
  }

  Future<Map<String, dynamic>> pause(String sessionId) async {
    final envelope = await _apiClient.post(
      '/workout-sessions/$sessionId/pause',
      (data) => data as Map<String, dynamic>,
    );
    return envelope.data!;
  }

  Future<Map<String, dynamic>> resume(String sessionId) async {
    final envelope = await _apiClient.post(
      '/workout-sessions/$sessionId/resume',
      (data) => data as Map<String, dynamic>,
    );
    return envelope.data!;
  }

  Future<(Map<String, dynamic> session, List<PersonalRecord> newRecords)>
  finish(String sessionId, {int? difficultyRating}) async {
    final envelope = await _apiClient.post(
      '/workout-sessions/$sessionId/finish',
      (data) => data as Map<String, dynamic>,
      data: {'difficultyRating': ?difficultyRating},
    );
    final body = envelope.data!;
    final records = (body['newPersonalRecords'] as List<dynamic>? ?? [])
        .map((r) => PersonalRecord.fromJson(r as Map<String, dynamic>))
        .toList();
    return (body['session'] as Map<String, dynamic>, records);
  }

  Future<Map<String, dynamic>> abandon(String sessionId) async {
    final envelope = await _apiClient.post(
      '/workout-sessions/$sessionId/abandon',
      (data) => data as Map<String, dynamic>,
    );
    return envelope.data!;
  }

  Future<Map<String, dynamic>> logSet(
    String sessionId,
    LoggedSet set, {
    String? idempotencyKey,
  }) async {
    final envelope = await _apiClient.post(
      '/workout-sessions/$sessionId/sets',
      (data) => data as Map<String, dynamic>,
      data: {
        'exerciseId': set.exerciseId,
        if (set.reps != null) 'reps': set.reps,
        if (set.weightKg != null) 'weightKg': set.weightKg,
        if (set.durationSeconds != null) 'durationSeconds': set.durationSeconds,
        if (set.distanceMeters != null) 'distanceMeters': set.distanceMeters,
        'isWarmup': set.isWarmup,
        'rpe': ?set.rpe,
        'idempotencyKey': ?idempotencyKey,
      },
    );
    return envelope.data!;
  }

  /// Applies an exercise substitution for the remainder of an active or
  /// paused session — already-completed sets under the original exercise
  /// are untouched (enforced server-side, see
  /// `WorkoutSessionsService.substituteExercise`).
  Future<Map<String, dynamic>> substituteExercise(
    String sessionId, {
    required String originalExerciseId,
    required String substituteExerciseId,
    String? idempotencyKey,
  }) async {
    final envelope = await _apiClient.post(
      '/workout-sessions/$sessionId/substitutions',
      (data) => data as Map<String, dynamic>,
      data: {
        'originalExerciseId': originalExerciseId,
        'substituteExerciseId': substituteExerciseId,
        'idempotencyKey': ?idempotencyKey,
      },
    );
    return envelope.data!;
  }
}
