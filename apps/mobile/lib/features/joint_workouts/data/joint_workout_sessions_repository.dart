import '../../../core/networking/api_client.dart';
import '../domain/joint_workout_session.dart';

/// Thin client for services/api/src/modules/joint-workouts — Build
/// Session 8 Part 9's friend-only joint workout sessions.
class JointWorkoutSessionsRepository {
  JointWorkoutSessionsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<JointWorkoutSession>> listMine() async {
    final envelope = await _apiClient.get(
      '/joint-workouts',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map((s) => JointWorkoutSession.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<JointWorkoutSession> create({
    String? title,
    List<String>? inviteeIds,
  }) async {
    final envelope = await _apiClient.post(
      '/joint-workouts',
      (data) => data as Map<String, dynamic>,
      data: {'title': ?title, 'inviteeIds': ?inviteeIds},
    );
    return JointWorkoutSession.fromJson(envelope.data!);
  }

  Future<JointWorkoutSession> getById(String sessionId) async {
    final envelope = await _apiClient.get(
      '/joint-workouts/$sessionId',
      (data) => data as Map<String, dynamic>,
    );
    return JointWorkoutSession.fromJson(envelope.data!);
  }

  Future<void> invite(String sessionId, String inviteeId) async {
    await _apiClient.post(
      '/joint-workouts/$sessionId/invite',
      (_) => null,
      data: {'inviteeId': inviteeId},
    );
  }

  Future<void> accept(String sessionId) async {
    await _apiClient.post('/joint-workouts/$sessionId/accept', (_) => null);
  }

  Future<void> decline(String sessionId) async {
    await _apiClient.post('/joint-workouts/$sessionId/decline', (_) => null);
  }

  Future<void> ready(String sessionId) async {
    await _apiClient.post('/joint-workouts/$sessionId/ready', (_) => null);
  }

  Future<void> start(String sessionId) async {
    await _apiClient.post('/joint-workouts/$sessionId/start', (_) => null);
  }

  Future<void> submitProgress(
    String sessionId, {
    String? exerciseName,
    int? setsCompleted,
    int? durationSeconds,
    double? distanceMeters,
    bool? isPersonalRecord,
  }) async {
    await _apiClient.post(
      '/joint-workouts/$sessionId/progress',
      (_) => null,
      data: {
        'exerciseName': ?exerciseName,
        'setsCompleted': ?setsCompleted,
        'durationSeconds': ?durationSeconds,
        'distanceMeters': ?distanceMeters,
        'isPersonalRecord': ?isPersonalRecord,
      },
    );
  }

  Future<void> finish(String sessionId) async {
    await _apiClient.post('/joint-workouts/$sessionId/finish', (_) => null);
  }

  Future<void> leave(String sessionId) async {
    await _apiClient.post('/joint-workouts/$sessionId/leave', (_) => null);
  }

  Future<void> cancel(String sessionId) async {
    await _apiClient.post('/joint-workouts/$sessionId/cancel', (_) => null);
  }
}
