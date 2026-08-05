import '../../../core/networking/api_client.dart';
import '../domain/device_connection.dart';

class DeviceRepository {
  DeviceRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<DeviceConnection>> list() async {
    final envelope = await _apiClient.get(
      '/devices',
      (data) => data as List<dynamic>,
    );
    return (envelope.data ?? [])
        .map((e) => DeviceConnection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DeviceConnection> connect({
    required String provider,
    required String displayName,
  }) async {
    final envelope = await _apiClient.post(
      '/devices',
      (data) => data as Map<String, dynamic>,
      data: {
        'provider': provider,
        'displayName': displayName,
        'status': 'CONNECTED',
      },
    );
    return DeviceConnection.fromJson(envelope.data!);
  }

  Future<void> disconnect(String id) async {
    await _apiClient.delete('/devices/$id', (data) => data);
  }
}
