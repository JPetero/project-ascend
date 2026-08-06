import '../../../core/networking/api_client.dart';
import '../../../core/sync/idempotency_key.dart';
import '../../achievements/domain/achievement.dart';
import '../domain/cardio_session.dart';

class CardioSessionInput {
  const CardioSessionInput({
    required this.activityType,
    this.source,
    required this.startedAt,
    required this.durationSeconds,
    this.distanceMeters,
    this.elevationGainMeters,
    this.estimatedCalories,
    this.regionLabel,
    this.hideRoute,
    this.hideStartLocation,
    this.hideEndLocation,
    this.routePoints,
    this.notes,
    String? idempotencyKey,
  }) : _idempotencyKey = idempotencyKey;

  final CardioActivityType activityType;
  final CardioSessionSource? source;
  final DateTime startedAt;
  final int durationSeconds;
  final double? distanceMeters;
  final double? elevationGainMeters;
  final double? estimatedCalories;
  final String? regionLabel;
  final bool? hideRoute;
  final bool? hideStartLocation;
  final bool? hideEndLocation;
  final List<RoutePoint>? routePoints;
  final String? notes;
  final String? _idempotencyKey;

  Map<String, dynamic> toJson() => {
    'activityType': cardioActivityTypeToJson(activityType),
    if (source != null) 'source': cardioSessionSourceToJson(source!),
    'startedAt': startedAt.toUtc().toIso8601String(),
    'durationSeconds': durationSeconds,
    'distanceMeters': ?distanceMeters,
    'elevationGainMeters': ?elevationGainMeters,
    'estimatedCalories': ?estimatedCalories,
    'regionLabel': ?regionLabel,
    'hideRoute': ?hideRoute,
    'hideStartLocation': ?hideStartLocation,
    'hideEndLocation': ?hideEndLocation,
    if (routePoints != null && routePoints!.isNotEmpty)
      'routePoints': routePoints!.map((p) => p.toJson()).toList(),
    'notes': ?notes,
    // A caller finishing a recovered/interrupted live session passes its
    // own stable idempotencyKey (the session's localId) so retrying the
    // same finish() after a crash never creates a duplicate server
    // session; every other caller gets a fresh one per call.
    'idempotencyKey':
        _idempotencyKey ?? generateIdempotencyKey('cardio-session'),
  };
}

class CardioSessionRepository {
  CardioSessionRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<CardioSession>> list({int page = 1, int limit = 20}) async {
    final envelope = await _apiClient.get(
      '/cardio-sessions',
      (data) => data as Map<String, dynamic>,
      query: {'page': page, 'limit': limit},
    );
    final items = envelope.data!['data'] as List<dynamic>;
    return items
        .map((s) => CardioSession.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  /// Returns both the created session and anything newly earned by
  /// logging it — see `CardioService.create`'s `meta.newAchievements` on
  /// the backend.
  Future<({CardioSession session, List<Achievement> newAchievements})> create(
    CardioSessionInput input,
  ) async {
    final envelope = await _apiClient.post(
      '/cardio-sessions',
      (data) => data as Map<String, dynamic>,
      data: input.toJson(),
    );
    final newAchievements =
        (envelope.meta['newAchievements'] as List<dynamic>? ?? [])
            .map((a) => Achievement.fromJson(a as Map<String, dynamic>))
            .toList();
    return (
      session: CardioSession.fromJson(envelope.data!),
      newAchievements: newAchievements,
    );
  }

  Future<CardioSession> updatePrivacy(
    String id, {
    bool? hideRoute,
    bool? hideStartLocation,
    bool? hideEndLocation,
    String? notes,
  }) async {
    final envelope = await _apiClient.patch(
      '/cardio-sessions/$id',
      (data) => data as Map<String, dynamic>,
      data: {
        'hideRoute': ?hideRoute,
        'hideStartLocation': ?hideStartLocation,
        'hideEndLocation': ?hideEndLocation,
        'notes': ?notes,
      },
    );
    return CardioSession.fromJson(envelope.data!);
  }

  Future<void> delete(String id) async {
    await _apiClient.delete('/cardio-sessions/$id', (_) => null);
  }
}
