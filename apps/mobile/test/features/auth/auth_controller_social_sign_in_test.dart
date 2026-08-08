import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/app_exception.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/fake_social_auth_providers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  group('AuthController.signInWithGoogle', () {
    test('authenticates and stores the resulting session on success', () async {
      final container = await createTestContainer();
      addTearDown(container.dispose);
      final fakeRepo =
          container.read(authRepositoryProvider) as FakeAuthRepository;

      await container.read(authControllerProvider.notifier).signInWithGoogle();

      expect(fakeRepo.signInWithGoogleCalled, isTrue);
      expect(fakeRepo.lastSocialIdToken, 'fake-google-id-token');
      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.isSubmitting, isFalse);
    });

    test(
      'a cancelled picker leaves the session untouched, not an error',
      () async {
        final fakeGoogle = FakeGoogleAuthProvider()..nextResult = null;
        final container = await createTestContainer(
          googleAuthProvider: fakeGoogle,
        );
        addTearDown(container.dispose);
        final fakeRepo =
            container.read(authRepositoryProvider) as FakeAuthRepository;

        await container
            .read(authControllerProvider.notifier)
            .signInWithGoogle();

        expect(fakeGoogle.signInCalled, isTrue);
        expect(fakeRepo.signInWithGoogleCalled, isFalse);
        final state = container.read(authControllerProvider);
        expect(state.status, isNot(AuthStatus.authenticated));
        expect(state.isSubmitting, isFalse);
      },
    );

    test('a provider failure resets isSubmitting and rethrows', () async {
      final fakeGoogle = FakeGoogleAuthProvider()
        ..nextError = const AppException(
          message: 'Google sign-in failed. Please try again.',
          code: 'UNKNOWN',
        );
      final container = await createTestContainer(
        googleAuthProvider: fakeGoogle,
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(authControllerProvider.notifier).signInWithGoogle(),
        throwsA(isA<AppException>()),
      );

      expect(container.read(authControllerProvider).isSubmitting, isFalse);
    });

    test('a backend rejection resets isSubmitting and rethrows', () async {
      final container = await createTestContainer();
      addTearDown(container.dispose);
      final fakeRepo =
          container.read(authRepositoryProvider) as FakeAuthRepository;
      fakeRepo.throwOnNextCall = true;

      await expectLater(
        container.read(authControllerProvider.notifier).signInWithGoogle(),
        throwsA(isA<AppException>()),
      );

      expect(container.read(authControllerProvider).isSubmitting, isFalse);
    });
  });

  group('AuthController.signInWithApple', () {
    test(
      'authenticates, forwarding the first-sign-in-only first name',
      () async {
        final container = await createTestContainer();
        addTearDown(container.dispose);
        final fakeRepo =
            container.read(authRepositoryProvider) as FakeAuthRepository;

        await container.read(authControllerProvider.notifier).signInWithApple();

        expect(fakeRepo.signInWithAppleCalled, isTrue);
        expect(fakeRepo.lastSocialIdToken, 'fake-apple-id-token');
        expect(fakeRepo.lastSocialFirstName, 'Ada');
        expect(
          container.read(authControllerProvider).status,
          AuthStatus.authenticated,
        );
      },
    );

    test(
      'a cancelled picker leaves the session untouched, not an error',
      () async {
        final fakeApple = FakeAppleAuthProvider()..nextResult = null;
        final container = await createTestContainer(
          appleAuthProvider: fakeApple,
        );
        addTearDown(container.dispose);
        final fakeRepo =
            container.read(authRepositoryProvider) as FakeAuthRepository;

        await container.read(authControllerProvider.notifier).signInWithApple();

        expect(fakeApple.signInCalled, isTrue);
        expect(fakeRepo.signInWithAppleCalled, isFalse);
        expect(
          container.read(authControllerProvider).status,
          isNot(AuthStatus.authenticated),
        );
      },
    );
  });

  group('AuthController.canSignInWithApple', () {
    test('reflects the injected provider availability', () async {
      final unavailable = await createTestContainer(
        appleAuthProvider: FakeAppleAuthProvider()..available = false,
      );
      addTearDown(unavailable.dispose);
      expect(
        unavailable.read(authControllerProvider.notifier).canSignInWithApple,
        isFalse,
      );

      final available = await createTestContainer();
      addTearDown(available.dispose);
      expect(
        available.read(authControllerProvider.notifier).canSignInWithApple,
        isTrue,
      );
    });
  });
}
