import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';
import 'package:mobile/features/auth/presentation/screens/forgot_password_screen.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('requires an email before submitting', (tester) async {
    final container = await createTestContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ForgotPasswordScreen()),
      ),
    );

    await tester.tap(find.text('Send reset link'));
    await tester.pump();

    expect(find.text('Enter your email.'), findsOneWidget);
  });

  testWidgets(
    'shows the same confirmation regardless of whether the email exists',
    (tester) async {
      final container = await createTestContainer();
      addTearDown(container.dispose);
      final fakeRepo =
          container.read(authRepositoryProvider) as FakeAuthRepository;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ForgotPasswordScreen()),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'ada@example.com',
      );
      await tester.tap(find.text('Send reset link'));
      await pumpForAsyncSettle(tester);

      expect(fakeRepo.lastForgotPasswordEmail, 'ada@example.com');
      expect(find.text('Check your email'), findsOneWidget);
    },
  );

  testWidgets('surfaces a server error instead of the confirmation', (
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
        child: const MaterialApp(home: ForgotPasswordScreen()),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'ada@example.com',
    );
    await tester.tap(find.text('Send reset link'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Check your email'), findsNothing);
    expect(find.text('Something went wrong.'), findsOneWidget);
  });
}
