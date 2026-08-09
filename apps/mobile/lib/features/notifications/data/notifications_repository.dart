import '../../../core/networking/api_client.dart';
import '../domain/notification_models.dart';

/// Thin client for services/api/src/modules/notifications — Build
/// Session 8 Part 12.
class NotificationsRepository {
  NotificationsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<NotificationPreferences> getPreferences() async {
    final envelope = await _apiClient.get(
      '/notifications/preferences',
      (data) => data as Map<String, dynamic>,
    );
    return NotificationPreferences.fromJson(envelope.data!);
  }

  Future<NotificationPreferences> updatePreferences(
    Map<String, bool> patch,
  ) async {
    final envelope = await _apiClient.patch(
      '/notifications/preferences',
      (data) => data as Map<String, dynamic>,
      data: patch,
    );
    return NotificationPreferences.fromJson(envelope.data!);
  }

  Future<List<NotificationEvent>> listEvents({bool unreadOnly = false}) async {
    final envelope = await _apiClient.get(
      '/notifications/events',
      (data) => data as List<dynamic>,
      query: unreadOnly ? {'unreadOnly': 'true'} : null,
    );
    return envelope.data!
        .map((e) => NotificationEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> unreadCount() async {
    final envelope = await _apiClient.get(
      '/notifications/events/unread-count',
      (data) => data as int,
    );
    return envelope.data!;
  }

  Future<void> markRead(String eventId) async {
    await _apiClient.post('/notifications/events/$eventId/read', (_) => null);
  }

  Future<void> markAllRead() async {
    await _apiClient.post('/notifications/events/read-all', (_) => null);
  }

  /// Registers (or refreshes) this device's remote push token (Build
  /// Session 11 Part 5) against the backend's existing
  /// `POST /notifications/device-tokens` endpoint.
  Future<void> registerDeviceToken({
    required String token,
    String? platform,
  }) async {
    await _apiClient.post(
      '/notifications/device-tokens',
      (_) => null,
      data: {'token': token, 'platform': ?platform},
    );
  }

  /// Removes this device's token — called on logout/account switch so a
  /// signed-out device stops receiving another account's push.
  Future<void> unregisterDeviceToken(String token) async {
    await _apiClient.delete('/notifications/device-tokens/$token', (_) => null);
  }
}
