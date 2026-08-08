import '../../../../core/networking/api_client.dart';
import '../domain/form_observation.dart';
import '../domain/supported_exercise.dart';
import '../domain/vision_analysis_session.dart';

/// The version tag saved with every result this analyzer build
/// produces — see VisionAnalysisSession's `analysisVersion` doc comment
/// on the backend for why this exists (distinguishing a future analyzer
/// change in stored history without guessing from the date).
const visionAnalysisVersion = 'pose-v1';

/// Thin client for `services/api/src/modules/vision` (Build Session 10
/// Part 6) — saving/reading/deleting a user's own live Vision session
/// results. Saving is opt-in: the live session screen calls [saveSession]
/// only after the user chooses to keep a completed session, never
/// automatically.
class VisionResultsRepository {
  VisionResultsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<VisionAnalysisSession> saveSession({
    required SupportedExercise exercise,
    required DateTime startedAt,
    required DateTime completedAt,
    required int autoRepCount,
    required int correctedRepCount,
    required List<FormObservation> observations,
    String? mediaAssetId,
    String? workoutSessionId,
  }) async {
    final envelope = await _apiClient.post(
      '/vision/analysis-sessions',
      (data) => data as Map<String, dynamic>,
      data: {
        'exercise': supportedExerciseToJson(exercise),
        'startedAt': startedAt.toUtc().toIso8601String(),
        'completedAt': completedAt.toUtc().toIso8601String(),
        'autoRepCount': autoRepCount,
        'correctedRepCount': correctedRepCount,
        'analysisVersion': visionAnalysisVersion,
        'mediaAssetId': ?mediaAssetId,
        'workoutSessionId': ?workoutSessionId,
        'observations': observations
            .map(
              (o) => {
                'type': o.type,
                'message': o.message,
                'severity': formObservationSeverityToJson(o.severity),
                'confidence': o.confidence,
                'occurredAt': o.timestamp.toUtc().toIso8601String(),
              },
            )
            .toList(),
      },
    );
    return VisionAnalysisSession.fromJson(envelope.data!);
  }

  Future<List<VisionAnalysisSession>> listSessions({
    int page = 1,
    int limit = 20,
  }) async {
    final envelope = await _apiClient.get(
      '/vision/analysis-sessions',
      (data) => data as Map<String, dynamic>,
      query: {'page': page, 'limit': limit},
    );
    final items = envelope.data!['data'] as List<dynamic>;
    return items
        .map((s) => VisionAnalysisSession.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<VisionAnalysisSession> getSession(String id) async {
    final envelope = await _apiClient.get(
      '/vision/analysis-sessions/$id',
      (data) => data as Map<String, dynamic>,
    );
    return VisionAnalysisSession.fromJson(envelope.data!);
  }

  Future<void> deleteSession(String id) async {
    await _apiClient.delete('/vision/analysis-sessions/$id', (_) => null);
  }
}
