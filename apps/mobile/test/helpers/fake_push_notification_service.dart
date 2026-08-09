import 'dart:async';

import 'package:mobile/core/notifications/push_notification_service.dart';

/// In-memory stand-in for [PushNotificationService] — never touches
/// Firebase platform channels, so it's the default override for every
/// widget test that builds `AscendApp` (see `test_provider_scope.dart`).
class FakePushNotificationService implements PushNotificationService {
  FakePushNotificationService({String? token}) : _token = token;

  final String? _token;
  int requestPermissionCallCount = 0;
  final _tokenRefreshController = StreamController<String>.broadcast();
  final _messageTapController = StreamController<PushNotificationMessage>.broadcast();
  PushNotificationMessage? initialMessage;

  @override
  Future<String?> requestPermissionAndGetToken() async {
    requestPermissionCallCount++;
    return _token;
  }

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  @override
  Stream<PushNotificationMessage> get onMessageTap =>
      _messageTapController.stream;

  @override
  Future<PushNotificationMessage?> consumeInitialMessage() async {
    final message = initialMessage;
    initialMessage = null;
    return message;
  }

  void emitTokenRefresh(String token) => _tokenRefreshController.add(token);

  void emitMessageTap(PushNotificationMessage message) =>
      _messageTapController.add(message);

  void dispose() {
    _tokenRefreshController.close();
    _messageTapController.close();
  }
}
