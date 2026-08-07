import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';
import 'package:mobile/features/auth/presentation/screens/reset_password_screen.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('pre-fills the reset code when an initial token is given', (
    tester,
  ) async {
    final container = await createTestContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ResetPasswordScreen(initialToken: 'reset-id.secret'),
        ),
      ),
    );

    expect(find.text('reset-id.secret'), findsOneWidget);
  });

  testWidgets('validates password strength and confirmation match', (
    tester,
  ) async {
    final container = await createTestContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ResetPasswordScreen(initialToken: 'reset-id.secret'),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'New password'),
      'weak',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm new password'),
      'Different1!',
    );
    await tester.tap(find.text('Reset password'));
    await tester.pump();

    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(find.text('Passwords do not match.'), findsOneWidget);
  });

  testWidgets('surfaces an invalid/expired token error from the server', (
    tester,
  ) async {
    final container = await createTestContainer();
    addTearDown(container.dispose);
    final fakeRepo =
        container.read(authRepositoryProvider) as FakeAuthRepository;
    fakeRepo.throwOnNextCall = true;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ResetPasswordScreen(initialToken: 'bad-token'),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'New password'),
      'NewStr0ngPass!',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm new password'),
      'NewStr0ngPass!',
    );
    await tester.tap(find.text('Reset password'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('This reset link is invalid or has expired.'),
      findsOneWidget,
    );
  });
}
