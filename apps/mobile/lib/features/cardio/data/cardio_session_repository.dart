import '../../../core/networking/api_client.dart';
import '../../../core/sync/idempotency_key.dart';
import '../domain/cardio_session.dart';

class CardioSessionInput {
  const CardioSessionInput({
    required this.activityType,
    required this.startedAt,
    required this.durationSeconds,
    this.distanceMeters,
    this.elevationGainMeters,
    this.estimatedCalories,
    this.regionLabel,
    this.hideRoute,
    this.hideStartLocation,
    this.hideEndLocation,
    this.notes,
  });

  final CardioActivityType activityType;
  final DateTime startedAt;
  final int durationSeconds;
  final double? distanceMeters;
  final double? elevationGainMeters;
  final double? estimatedCalories;
  final String? regionLabel;
  final bool? hideRoute;
  final bool? hideStartLocation;
  final bool? hideEndLocation;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'activityType': cardioActivityTypeToJson(activityType),
    'startedAt': startedAt.toUtc().toIso8601String(),
    'durationSeconds': durationSeconds,
    'distanceMeters': ?distanceMeters,
    'elevationGainMeters': ?elevationGainMeters,
    'estimatedCalories': ?estimatedCalories,
    'regionLabel': ?regionLabel,
    'hideRoute': ?hideRoute,
    'hideStartLocation': ?hideStartLocation,
    'hideEndLocation': ?hideEndLocation,
    'notes': ?notes,
    'idempotencyKey': generateIdempotencyKey('cardio-session'),
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

  Future<CardioSession> create(CardioSessionInput input) async {
    final envelope = await _apiClient.post(
      '/cardio-sessions',
      (data) => data as Map<String, dynamic>,
      data: input.toJson(),
    );
    return CardioSession.fromJson(envelope.data!);
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
