import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/notifications/push_notification_service.dart';
import 'package:mobile/features/notifications/presentation/providers/push_registration_controller.dart';

import '../../helpers/fake_notifications_repository.dart';
import '../../helpers/fake_push_notification_service.dart';

void main() {
  group('PushRegistrationController', () {
    test('registers the token once permission is granted on sign-in', () async {
      final pushService = FakePushNotificationService(token: 'fcm-token-1');
      final repository = FakeNotificationsRepository();
      final navigated = <String>[];
      final controller = PushRegistrationController(
        pushService: pushService,
        repository: repository,
        navigate: navigated.add,
      );
      addTearDown(controller.dispose);

      await controller.onSignedIn();

      expect(pushService.requestPermissionCallCount, 1);
      expect(repository.registeredTokens, ['fcm-token-1']);
    });

    test('never calls the repository when permission is denied', () async {
      final pushService = FakePushNotificationService(token: null);
      final repository = FakeNotificationsRepository();
      final controller = PushRegistrationController(
        pushService: pushService,
        repository: repository,
        navigate: (_) {},
      );
      addTearDown(controller.dispose);

      await controller.onSignedIn();

      expect(repository.registeredTokens, isEmpty);
    });

    test('unregisters the last registered token on sign-out', () async {
      final pushService = FakePushNotificationService(token: 'fcm-token-1');
      final repository = FakeNotificationsRepository();
      final controller = PushRegistrationController(
        pushService: pushService,
        repository: repository,
        navigate: (_) {},
      );
      addTearDown(controller.dispose);

      await controller.onSignedIn();
      await controller.onSignedOut();

      expect(repository.unregisteredTokens, ['fcm-token-1']);
    });

    test(
      'does nothing on sign-out when no token was ever registered',
      () async {
        final pushService = FakePushNotificationService(token: null);
        final repository = FakeNotificationsRepository();
        final controller = PushRegistrationController(
          pushService: pushService,
          repository: repository,
          navigate: (_) {},
        );
        addTearDown(controller.dispose);

        await controller.onSignedOut();

        expect(repository.unregisteredTokens, isEmpty);
      },
    );

    test('re-registers whenever FCM rotates the token', () async {
      final pushService = FakePushNotificationService(token: 'fcm-token-1');
      final repository = FakeNotificationsRepository();
      final controller = PushRegistrationController(
        pushService: pushService,
        repository: repository,
        navigate: (_) {},
      );
      addTearDown(controller.dispose);

      pushService.emitTokenRefresh('fcm-token-2');
      await Future<void>.delayed(Duration.zero);

      expect(repository.registeredTokens, ['fcm-token-2']);
    });

    test(
      'navigates to the deep link for a tapped direct-message push',
      () async {
        final pushService = FakePushNotificationService();
        final repository = FakeNotificationsRepository();
        final navigated = <String>[];
        final controller = PushRegistrationController(
          pushService: pushService,
          repository: repository,
          navigate: navigated.add,
        );
        addTearDown(controller.dispose);

        pushService.emitMessageTap(
          const PushNotificationMessage(
            type: 'DIRECT_MESSAGE',
            data: 'conversation-1',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(navigated, ['/messages/conversation-1']);
      },
    );

    test('ignores a tap with no type and does not navigate', () async {
      final pushService = FakePushNotificationService();
      final repository = FakeNotificationsRepository();
      final navigated = <String>[];
      final controller = PushRegistrationController(
        pushService: pushService,
        repository: repository,
        navigate: navigated.add,
      );
      addTearDown(controller.dispose);

      pushService.emitMessageTap(const PushNotificationMessage());
      await Future<void>.delayed(Duration.zero);

      expect(navigated, isEmpty);
    });

    test(
      'navigates from the initial message on a terminated-launch tap',
      () async {
        final pushService = FakePushNotificationService()
          ..initialMessage = const PushNotificationMessage(
            type: 'CHALLENGE',
            data: 'challenge-1',
          );
        final repository = FakeNotificationsRepository();
        final navigated = <String>[];
        final controller = PushRegistrationController(
          pushService: pushService,
          repository: repository,
          navigate: navigated.add,
        );
        addTearDown(controller.dispose);

        await Future<void>.delayed(Duration.zero);

        expect(navigated, ['/leaderboards/challenges/challenge-1']);
      },
    );
  });
}
