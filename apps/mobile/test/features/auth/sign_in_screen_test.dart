import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/app_exception.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';
import 'package:mobile/features/auth/presentation/screens/sign_in_screen.dart';

import '../../helpers/fake_social_auth_providers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets(
    'offers real Google and Apple continue buttons (Build Session 10 Parts 9/10)',
    (tester) async {
      final container = await createTestContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SignInScreen()),
        ),
      );

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
    },
  );

  testWidgets('tapping Continue with Google signs the user in', (tester) async {
    final container = await createTestContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SignInScreen()),
      ),
    );

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(
      container.read(authControllerProvider).status,
      AuthStatus.authenticated,
    );
  });

  testWidgets('a Google sign-in failure shows the real error message', (
    tester,
  ) async {
    final fakeGoogle = FakeGoogleAuthProvider()
      ..nextError = const AppException(
        message: 'Google sign-in isn\'t configured for this build yet.',
        code: 'UNKNOWN',
      );
    final container = await createTestContainer(googleAuthProvider: fakeGoogle);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SignInScreen()),
      ),
    );

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(
      find.text('Google sign-in isn\'t configured for this build yet.'),
      findsOneWidget,
    );
    expect(
      container.read(authControllerProvider).status,
      isNot(AuthStatus.authenticated),
    );
  });

  testWidgets('hides the Apple button where Apple sign-in is unavailable', (
    tester,
  ) async {
    final container = await createTestContainer(
      appleAuthProvider: FakeAppleAuthProvider()..available = false,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SignInScreen()),
      ),
    );

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsNothing);
  });
}
