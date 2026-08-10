import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/notifications/presentation/providers/push_registration_controller.dart';

import '../../helpers/fake_feature_flags_repository.dart';
import '../../helpers/fake_notifications_repository.dart';
import '../../helpers/fake_push_notification_service.dart';
import '../../helpers/test_provider_scope.dart';

/// Build Session 13 continuation Part A — REMOTE_PUSH gates registration
/// through [pushRegistrationControllerProvider] specifically (the
/// [PushRegistrationController] class itself has no flag awareness; see
/// push_registration_controller_test.dart for its own behavior in
/// isolation).
void main() {
  test(
    'does not register a device token when REMOTE_PUSH is explicitly disabled',
    () async {
      final pushService = FakePushNotificationService(token: 'fcm-token-1');
      final repository = FakeNotificationsRepository();
      final container = await createTestContainer(
        signedIn: true,
        pushNotificationService: pushService,
        notificationsRepository: repository,
        featureFlagsRepository: FakeFeatureFlagsRepository(
          flags: const {'REMOTE_PUSH': false},
        ),
      );
      addTearDown(container.dispose);

      container.read(pushRegistrationControllerProvider);
      await Future<void>.delayed(Duration.zero);

      expect(repository.registeredTokens, isEmpty);
    },
  );

  test(
    'registers a device token when REMOTE_PUSH is enabled (the default)',
    () async {
      final pushService = FakePushNotificationService(token: 'fcm-token-1');
      final repository = FakeNotificationsRepository();
      final container = await createTestContainer(
        signedIn: true,
        pushNotificationService: pushService,
        notificationsRepository: repository,
      );
      addTearDown(container.dispose);

      container.read(pushRegistrationControllerProvider);
      await Future<void>.delayed(Duration.zero);

      expect(repository.registeredTokens, ['fcm-token-1']);
    },
  );

  test(
    'registers a device token when the flag API is unavailable (REMOTE_PUSH fails open, SAFE_CORE)',
    () async {
      final pushService = FakePushNotificationService(token: 'fcm-token-1');
      final repository = FakeNotificationsRepository();
      final container = await createTestContainer(
        signedIn: true,
        pushNotificationService: pushService,
        notificationsRepository: repository,
        featureFlagsRepository: FakeFeatureFlagsRepository(
          throwOnResolve: true,
        ),
      );
      addTearDown(container.dispose);

      container.read(pushRegistrationControllerProvider);
      await Future<void>.delayed(Duration.zero);

      expect(repository.registeredTokens, ['fcm-token-1']);
    },
  );
}
