import '../../../core/networking/api_client.dart';
import '../domain/health_sample.dart';

/// Backend counterpart of services/api/src/modules/health-metrics/ — not
/// `/health` (the public liveness check). See packages/docs/wearables.md.
class HealthMetricsRepository {
  HealthMetricsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<HealthSyncResult> sync({
    required String provider,
    required List<HealthSample> samples,
  }) async {
    final envelope = await _apiClient.post(
      '/health-metrics/sync',
      (data) => data as Map<String, dynamic>,
      data: {
        'provider': provider,
        'samples': samples.map((s) => s.toJson()).toList(),
      },
    );
    return HealthSyncResult.fromJson(envelope.data!);
  }

  Future<List<HealthSyncCursorInfo>> syncStatus() async {
    final envelope = await _apiClient.get(
      '/health-metrics/sync-status',
      (data) => data as Map<String, dynamic>,
    );
    final items = envelope.data!['data'] as List<dynamic>;
    return items
        .map((c) => HealthSyncCursorInfo.fromJson(c as Map<String, dynamic>))
        .toList();
  }
}
