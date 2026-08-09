import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'push_notification_service.dart';

const _foregroundChannelId = 'ascend_push';
const _foregroundChannelName = 'Ascend';
const _foregroundChannelDescription =
    'Messages, friend activity, and other updates from Ascend.';

/// Real, Firebase-backed implementation (Build Session 11 Part 5). No live
/// Firebase project exists in this environment — no
/// `google-services.json`/`GoogleService-Info.plist`, and the Android
/// Gradle project deliberately does not apply the `google-services` plugin
/// without one (that plugin fails the build outright when the config file
/// is missing, which would break every developer's local build). Because
/// of that, `Firebase.initializeApp()` here has no default options to read
/// and will throw — `_ensureInitialized` catches that and every method
/// after it honestly reports push as unavailable instead of crashing, the
/// same "not configured" pattern `FcmPushNotificationProvider` uses on the
/// backend. Once a real Firebase project is created, dropping in the two
/// config files (and, for Android, applying the `google-services` plugin)
/// is the only change required — this class does not need to change.
class FirebasePushNotificationService implements PushNotificationService {
  bool? _available;
  final _localPlugin = FlutterLocalNotificationsPlugin();
  bool _localPluginInitialized = false;
  bool _initialMessageConsumed = false;

  Future<bool> _ensureInitialized() async {
    if (_available != null) return _available!;
    try {
      await Firebase.initializeApp();
      _available = true;
    } catch (error) {
      debugPrint(
        'Push notifications unavailable: Firebase not configured ($error).',
      );
      _available = false;
    }
    return _available!;
  }

  Future<void> _ensureLocalPluginInitialized() async {
    if (_localPluginInitialized) return;
    await _localPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _localPluginInitialized = true;
  }

  @override
  Future<String?> requestPermissionAndGetToken() async {
    if (!await _ensureInitialized()) return null;

    final settings = await FirebaseMessaging.instance.requestPermission();
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!granted) return null;

    _wireForegroundDisplay();
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (error) {
      debugPrint('Failed to obtain FCM token: $error');
      return null;
    }
  }

  @override
  Stream<String> get onTokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<PushNotificationMessage> get onMessageTap =>
      FirebaseMessaging.onMessageOpenedApp.map(_toMessage);

  @override
  Future<PushNotificationMessage?> consumeInitialMessage() async {
    if (_initialMessageConsumed) return null;
    _initialMessageConsumed = true;

    if (!await _ensureInitialized()) return null;
    final remoteMessage = await FirebaseMessaging.instance.getInitialMessage();
    return remoteMessage == null ? null : _toMessage(remoteMessage);
  }

  PushNotificationMessage _toMessage(RemoteMessage message) {
    return PushNotificationMessage(
      type: message.data['type'] as String?,
      data: message.data['payload'] as String?,
    );
  }

  /// A foreground-received push shows no OS banner on Android by default
  /// (only background/terminated notifications do) — this mirrors that
  /// with a local notification via the already-integrated
  /// `flutter_local_notifications` plugin, kept deliberately generic (title
  /// and body only, whatever the backend sent) rather than adding a second
  /// notification pipeline.
  void _wireForegroundDisplay() {
    FirebaseMessaging.onMessage.listen((message) async {
      final notification = message.notification;
      if (notification == null) return;
      await _ensureLocalPluginInitialized();
      await _localPlugin.show(
        message.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _foregroundChannelId,
            _foregroundChannelName,
            channelDescription: _foregroundChannelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });
  }
}
