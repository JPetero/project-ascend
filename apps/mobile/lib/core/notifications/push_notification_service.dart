/// Remote push delivery (Build Session 11 Part 5) — a thin boundary over
/// Firebase Cloud Messaging, mirroring `LocalNotificationSchedulingService`'s
/// interface-over-plugin style so callers stay fake-able in tests. Unlike
/// local notifications, remote push requires a live Firebase project; no
/// `google-services.json`/`GoogleService-Info.plist` exists in this
/// environment, so every method must degrade honestly (return
/// false/null/empty) rather than throw when Firebase isn't configured —
/// see `FirebasePushNotificationService`'s defensive `_ensureInitialized`.
library;

/// The `type`/`data` pair the backend's FCM `data` payload carries (Build
/// Session 11 Part 5 backend fix) — enough to reconstruct the same
/// `deepLinkPathFor(type, data)` call the in-app notifications inbox
/// already uses. [type] is the raw `NotificationType` string (e.g.
/// `"DIRECT_MESSAGE"`); unrecognized values are handled by
/// `notificationEventTypeFromJson`'s existing fallback.
class PushNotificationMessage {
  const PushNotificationMessage({this.type, this.data});

  final String? type;
  final String? data;
}

abstract class PushNotificationService {
  /// Requests the OS notification permission and, if granted, the current
  /// FCM registration token. Returns null if permission was denied or no
  /// push provider is configured — callers must treat that as "push is
  /// unavailable" rather than retrying in a loop.
  Future<String?> requestPermissionAndGetToken();

  /// Fires whenever FCM issues a new token for this installation (token
  /// rotation, app reinstall). Callers must re-register on every event.
  Stream<String> get onTokenRefresh;

  /// Fires when the user taps a push notification that opened or resumed
  /// the app (background or foreground tap) — never for terminated-launch
  /// taps, see [consumeInitialMessage] for that case.
  Stream<PushNotificationMessage> get onMessageTap;

  /// The push that launched the app from a fully terminated state, if any.
  /// Must only be consulted once per app launch — a second call after the
  /// first returns null, since re-navigating to the same target on every
  /// rebuild would fight the user's own subsequent navigation.
  Future<PushNotificationMessage?> consumeInitialMessage();
}
