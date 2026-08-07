import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';
import 'package:mobile/features/auth/presentation/screens/change_password_screen.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('requires the current password and a strong new password', (
    tester,
  ) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ChangePasswordScreen()),
      ),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Change password'));
    await tester.pump();

    expect(find.text('Enter your current password.'), findsOneWidget);
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
  });

  testWidgets('surfaces an incorrect-current-password error from the server', (
    tester,
  ) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);
    final fakeRepo =
        container.read(authRepositoryProvider) as FakeAuthRepository;
    fakeRepo.throwOnNextCall = true;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ChangePasswordScreen()),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Current password'),
      'wrong-password',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New password'),
      'NewStr0ngPass!',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm new password'),
      'NewStr0ngPass!',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Change password'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Current password is incorrect.'), findsOneWidget);
    expect(fakeRepo.changePasswordCalled, isFalse);
  });
}
