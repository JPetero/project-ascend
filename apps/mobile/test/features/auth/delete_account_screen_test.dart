import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';
import 'package:mobile/features/auth/presentation/screens/delete_account_screen.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('requires a password before submitting', (tester) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DeleteAccountScreen()),
      ),
    );

    await tester.tap(find.text('Permanently delete my account'));
    await tester.pump();

    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets(
    'surfaces an incorrect-password error and keeps the session intact',
    (tester) async {
      final container = await createTestContainer(signedIn: true);
      addTearDown(container.dispose);
      final fakeRepo =
          container.read(authRepositoryProvider) as FakeAuthRepository;
      fakeRepo.throwOnNextCall = true;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DeleteAccountScreen()),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm your password'),
        'wrong-password',
      );
      await tester.tap(find.text('Permanently delete my account'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Current password is incorrect.'), findsOneWidget);
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.authenticated,
      );
    },
  );

  testWidgets('deleting with the correct password clears the session', (
    tester,
  ) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);
    final fakeRepo =
        container.read(authRepositoryProvider) as FakeAuthRepository;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DeleteAccountScreen()),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm your password'),
      'Str0ngPass!',
    );
    await tester.tap(find.text('Permanently delete my account'));
    await tester.pump();
    await tester.pump();

    expect(fakeRepo.lastDeleteAccountPassword, 'Str0ngPass!');
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
  });
}
