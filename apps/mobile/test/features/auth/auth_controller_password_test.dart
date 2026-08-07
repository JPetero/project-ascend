import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  group('AuthController password recovery / verification', () {
    test('forgotPassword calls through to the repository', () async {
      final container = await createTestContainer();
      addTearDown(container.dispose);
      final fakeRepo =
          container.read(authRepositoryProvider) as FakeAuthRepository;

      await container
          .read(authControllerProvider.notifier)
          .forgotPassword('ada@example.com');

      expect(fakeRepo.lastForgotPasswordEmail, 'ada@example.com');
    });

    test('resetPassword calls through to the repository', () async {
      final container = await createTestContainer();
      addTearDown(container.dispose);
      final fakeRepo =
          container.read(authRepositoryProvider) as FakeAuthRepository;

      await container
          .read(authControllerProvider.notifier)
          .resetPassword(
            token: 'reset-id.secret',
            newPassword: 'NewStr0ngPass!',
            confirmNewPassword: 'NewStr0ngPass!',
          );

      expect(fakeRepo.lastResetPasswordToken, 'reset-id.secret');
    });

    test('changePassword calls through to the repository', () async {
      final container = await createTestContainer();
      addTearDown(container.dispose);
      final fakeRepo =
          container.read(authRepositoryProvider) as FakeAuthRepository;

      await container
          .read(authControllerProvider.notifier)
          .changePassword(
            currentPassword: 'Str0ngPass!',
            newPassword: 'NewStr0ngPass!',
            confirmNewPassword: 'NewStr0ngPass!',
          );

      expect(fakeRepo.changePasswordCalled, isTrue);
    });

    test('resendVerification calls through to the repository', () async {
      final container = await createTestContainer();
      addTearDown(container.dispose);
      final fakeRepo =
          container.read(authRepositoryProvider) as FakeAuthRepository;

      await container
          .read(authControllerProvider.notifier)
          .resendVerification();

      expect(fakeRepo.resendVerificationCalled, isTrue);
    });

    test('isSubmitting toggles around forgotPassword', () async {
      final container = await createTestContainer();
      addTearDown(container.dispose);

      final future = container
          .read(authControllerProvider.notifier)
          .forgotPassword('ada@example.com');
      expect(container.read(authControllerProvider).isSubmitting, isTrue);

      await future;
      expect(container.read(authControllerProvider).isSubmitting, isFalse);
    });
  });
}
