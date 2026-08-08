import 'package:mobile/features/vision/pose_analysis/data/vision_results_repository.dart';
import 'package:mobile/features/vision/pose_analysis/domain/form_observation.dart';
import 'package:mobile/features/vision/pose_analysis/domain/supported_exercise.dart';
import 'package:mobile/features/vision/pose_analysis/domain/vision_analysis_session.dart';

VisionAnalysisSession sampleVisionSession({
  String id = 'session-1',
  SupportedExercise exercise = SupportedExercise.bodyweightSquat,
  int autoRepCount = 8,
  int correctedRepCount = 9,
  List<FormObservation> observations = const [],
}) {
  final now = DateTime.utc(2026, 1, 1);
  return VisionAnalysisSession(
    id: id,
    exercise: exercise,
    startedAt: now,
    completedAt: now.add(const Duration(minutes: 5)),
    autoRepCount: autoRepCount,
    correctedRepCount: correctedRepCount,
    analysisVersion: visionAnalysisVersion,
    observations: observations,
    createdAt: now,
  );
}

class FakeVisionResultsRepository implements VisionResultsRepository {
  final List<VisionAnalysisSession> sessions = [];
  bool failList = false;
  bool failDelete = false;
  bool failSave = false;
  int saveCallCount = 0;
  int deleteCallCount = 0;

  @override
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
    saveCallCount++;
    if (failSave) throw Exception('save failed');
    final session = VisionAnalysisSession(
      id: 'saved-$saveCallCount',
      exercise: exercise,
      startedAt: startedAt,
      completedAt: completedAt,
      autoRepCount: autoRepCount,
      correctedRepCount: correctedRepCount,
      analysisVersion: visionAnalysisVersion,
      observations: observations,
      mediaAssetId: mediaAssetId,
      workoutSessionId: workoutSessionId,
      createdAt: completedAt,
    );
    sessions.insert(0, session);
    return session;
  }

  @override
  Future<List<VisionAnalysisSession>> listSessions({
    int page = 1,
    int limit = 20,
  }) async {
    if (failList) throw Exception('list failed');
    return List.unmodifiable(sessions);
  }

  @override
  Future<VisionAnalysisSession> getSession(String id) async {
    return sessions.firstWhere((s) => s.id == id);
  }

  @override
  Future<void> deleteSession(String id) async {
    deleteCallCount++;
    if (failDelete) throw Exception('delete failed');
    sessions.removeWhere((s) => s.id == id);
  }
}
