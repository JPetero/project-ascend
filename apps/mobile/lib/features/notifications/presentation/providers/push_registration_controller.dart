import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/firebase_push_notification_service.dart';
import '../../../../core/notifications/push_notification_service.dart';
import '../../../../core/routing/app_router.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification_deep_link.dart';
import '../../domain/notification_models.dart';
import 'notifications_controller.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  return FirebasePushNotificationService();
});

/// Wires remote push end to end (Build Session 11 Parts 5/6): registers
/// (and refreshes) this device's token whenever the user is authenticated,
/// unregisters it on sign-out, and turns a tapped push into the same
/// in-app navigation `deepLinkPathFor` already gives the notifications
/// inbox. Constructed once and kept alive by `AscendApp` watching
/// [pushRegistrationControllerProvider] — Riverpod providers are otherwise
/// lazy and this wiring would never run.
class PushRegistrationController {
  PushRegistrationController({
    required PushNotificationService pushService,
    required NotificationsRepository repository,
    required void Function(String path) navigate,
  }) : _pushService = pushService,
       _repository = repository,
       _navigate = navigate {
    _tokenRefreshSubscription = _pushService.onTokenRefresh.listen(_register);
    _tapSubscription = _pushService.onMessageTap.listen(_handleTap);
    _pushService.consumeInitialMessage().then((message) {
      if (message != null) _handleTap(message);
    });
  }

  final PushNotificationService _pushService;
  final NotificationsRepository _repository;
  final void Function(String path) _navigate;
  late final StreamSubscription<String> _tokenRefreshSubscription;
  late final StreamSubscription<PushNotificationMessage> _tapSubscription;
  String? _lastRegisteredToken;

  /// Freeform label sent with the token, purely informational — mirrors
  /// `AuthRepository._currentPlatform`.
  String? get _platform {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return null;
  }

  Future<void> onSignedIn() async {
    final token = await _pushService.requestPermissionAndGetToken();
    if (token != null) await _register(token);
  }

  /// Unregisters the last known token so a signed-out device (or one that
  /// switched accounts) stops receiving the previous account's push.
  Future<void> onSignedOut() async {
    final token = _lastRegisteredToken;
    _lastRegisteredToken = null;
    if (token == null) return;
    try {
      await _repository.unregisterDeviceToken(token);
    } catch (error) {
      debugPrint('Failed to unregister push token on sign-out: $error');
    }
  }

  Future<void> _register(String token) async {
    try {
      await _repository.registerDeviceToken(token: token, platform: _platform);
      _lastRegisteredToken = token;
    } catch (error) {
      debugPrint('Failed to register push token: $error');
    }
  }

  void _handleTap(PushNotificationMessage message) {
    final type = message.type;
    if (type == null) return;
    final path = deepLinkPathFor(
      notificationEventTypeFromJson(type),
      message.data,
    );
    if (path != null) _navigate(path);
  }

  void dispose() {
    _tokenRefreshSubscription.cancel();
    _tapSubscription.cancel();
  }
}

final pushRegistrationControllerProvider = Provider<PushRegistrationController>(
  (ref) {
    final controller = PushRegistrationController(
      pushService: ref.watch(pushNotificationServiceProvider),
      repository: ref.watch(notificationsRepositoryProvider),
      navigate: (path) => ref.read(routerProvider).push(path),
    );
    ref.onDispose(controller.dispose);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final wasAuthenticated = previous?.status == AuthStatus.authenticated;
      final isAuthenticated = next.status == AuthStatus.authenticated;
      if (isAuthenticated && !wasAuthenticated) {
        controller.onSignedIn();
      } else if (!isAuthenticated && wasAuthenticated) {
        controller.onSignedOut();
      }
    }, fireImmediately: true);

    return controller;
  },
);
