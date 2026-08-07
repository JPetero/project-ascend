import '../../../core/networking/api_client.dart';
import '../domain/challenge.dart';

/// Thin client for services/api/src/modules/challenges — create/discover/
/// join/leave time-boxed challenges.
class ChallengesRepository {
  ChallengesRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Challenge> create({
    required String title,
    String? description,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final envelope = await _apiClient.post(
      '/challenges',
      (data) => data as Map<String, dynamic>,
      data: {
        'title': title,
        'description': ?description,
        'startsAt': startsAt.toUtc().toIso8601String(),
        'endsAt': endsAt.toUtc().toIso8601String(),
      },
    );
    return Challenge.fromJson(envelope.data!);
  }

  Future<List<Challenge>> listMine() async {
    final envelope = await _apiClient.get(
      '/challenges',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map((c) => Challenge.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<List<Challenge>> listDiscoverable({
    int page = 1,
    int limit = 20,
  }) async {
    final envelope = await _apiClient.get(
      '/challenges/discover',
      (data) => data as Map<String, dynamic>,
      query: {'page': page, 'limit': limit},
    );
    final items = envelope.data!['data'] as List<dynamic>;
    return items
        .map((c) => Challenge.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<ChallengeDetail> getById(String id) async {
    final envelope = await _apiClient.get(
      '/challenges/$id',
      (data) => data as Map<String, dynamic>,
    );
    return ChallengeDetail.fromJson(envelope.data!);
  }

  Future<void> join(String id) async {
    await _apiClient.post('/challenges/$id/join', (_) => null);
  }

  Future<void> leave(String id) async {
    await _apiClient.delete('/challenges/$id/leave', (_) => null);
  }

  Future<void> delete(String id) async {
    await _apiClient.delete('/challenges/$id', (_) => null);
  }
}
