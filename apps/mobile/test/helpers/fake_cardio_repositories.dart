import 'package:mobile/features/achievements/domain/achievement.dart';
import 'package:mobile/features/cardio/data/cardio_session_repository.dart';
import 'package:mobile/features/cardio/domain/cardio_session.dart';

final sampleCardioSession = CardioSession(
  id: 'cardio-1',
  activityType: CardioActivityType.run,
  startedAt: DateTime.utc(2026, 8, 6, 8),
  durationSeconds: 1800,
  distanceMeters: 5000,
  hideRoute: true,
  hideStartLocation: true,
  hideEndLocation: true,
);

/// In-memory stand-in for cardio session logging.
class FakeCardioSessionRepository implements CardioSessionRepository {
  FakeCardioSessionRepository({List<CardioSession>? sessions})
    : _sessions = sessions ?? [];

  final List<CardioSession> _sessions;
  int _idCounter = 0;

  /// Achievements returned by the *next* [create] call.
  List<Achievement> nextAchievements = const [];

  @override
  Future<List<CardioSession>> list({int page = 1, int limit = 20}) async {
    final sorted = List<CardioSession>.of(_sessions)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return List.unmodifiable(sorted);
  }

  @override
  Future<({CardioSession session, List<Achievement> newAchievements})> create(
    CardioSessionInput input,
  ) async {
    final session = CardioSession(
      id: 'cardio-${_idCounter++}',
      activityType: input.activityType,
      startedAt: input.startedAt,
      durationSeconds: input.durationSeconds,
      distanceMeters: input.distanceMeters,
      elevationGainMeters: input.elevationGainMeters,
      estimatedCalories: input.estimatedCalories,
      regionLabel: input.regionLabel,
      hideRoute: input.hideRoute ?? true,
      hideStartLocation: input.hideStartLocation ?? true,
      hideEndLocation: input.hideEndLocation ?? true,
      notes: input.notes,
    );
    _sessions.add(session);
    return (session: session, newAchievements: nextAchievements);
  }

  @override
  Future<CardioSession> updatePrivacy(
    String id, {
    bool? hideRoute,
    bool? hideStartLocation,
    bool? hideEndLocation,
    String? notes,
  }) async {
    final index = _sessions.indexWhere((s) => s.id == id);
    final existing = _sessions[index];
    final updated = CardioSession(
      id: existing.id,
      activityType: existing.activityType,
      startedAt: existing.startedAt,
      durationSeconds: existing.durationSeconds,
      distanceMeters: existing.distanceMeters,
      elevationGainMeters: existing.elevationGainMeters,
      estimatedCalories: existing.estimatedCalories,
      regionLabel: existing.regionLabel,
      hideRoute: hideRoute ?? existing.hideRoute,
      hideStartLocation: hideStartLocation ?? existing.hideStartLocation,
      hideEndLocation: hideEndLocation ?? existing.hideEndLocation,
      notes: notes ?? existing.notes,
    );
    _sessions[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    _sessions.removeWhere((s) => s.id == id);
  }
}
