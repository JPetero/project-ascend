import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/device_session.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';
import 'package:mobile/features/auth/presentation/screens/account_security_screen.dart';
import 'package:mobile/features/auth/presentation/screens/change_password_screen.dart';
import 'package:mobile/features/auth/presentation/screens/delete_account_screen.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  Future<void> scrollUntilFound(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('shows the signed-in email and connected identities', (
    tester,
  ) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AccountSecurityScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ada@example.com'), findsOneWidget);
    expect(find.textContaining('Signed in with'), findsOneWidget);
    expect(find.textContaining('test@example.com'), findsOneWidget);
  });

  testWidgets(
    'shows a verify-email banner for an unverified account and resends on tap',
    (tester) async {
      final container = await createTestContainer(signedIn: true);
      addTearDown(container.dispose);
      final fakeRepo =
          container.read(authRepositoryProvider) as FakeAuthRepository;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AccountSecurityScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verify your email'), findsOneWidget);

      await tester.tap(find.text('Resend'));
      await tester.pumpAndSettle();

      expect(fakeRepo.resendVerificationCalled, isTrue);
    },
  );

  testWidgets('navigates to Change password', (tester) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AccountSecurityScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();

    expect(find.byType(ChangePasswordScreen), findsOneWidget);
  });

  testWidgets(
    'signing out everywhere requires confirmation, then clears the session',
    (tester) async {
      final container = await createTestContainer(signedIn: true);
      addTearDown(container.dispose);
      final fakeRepo =
          container.read(authRepositoryProvider) as FakeAuthRepository;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AccountSecurityScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await scrollUntilFound(tester, find.text('Sign out everywhere'));

      await tester.tap(find.text('Sign out everywhere'));
      await tester.pumpAndSettle();

      // Confirmation dialog — cancel first, must not call through.
      expect(find.text('Sign out of every device?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(fakeRepo.signOutEverywhereCalled, isFalse);

      await scrollUntilFound(tester, find.text('Sign out everywhere'));
      await tester.tap(find.text('Sign out everywhere'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Sign out everywhere'));
      await tester.pumpAndSettle();

      expect(fakeRepo.signOutEverywhereCalled, isTrue);
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.unauthenticated,
      );
    },
  );

  testWidgets('lists every device and marks the current one', (tester) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);
    final fakeRepo =
        container.read(authRepositoryProvider) as FakeAuthRepository;
    fakeRepo.sessions = [
      DeviceSession(
        id: 'family-current',
        deviceName: 'iPhone 15',
        platform: 'ios',
        createdAt: DateTime(2026, 1, 1),
        lastUsedAt: DateTime(2026, 1, 2),
        current: true,
      ),
      DeviceSession(
        id: 'family-other',
        deviceName: 'Pixel 9',
        platform: 'android',
        createdAt: DateTime(2026, 1, 1),
        lastUsedAt: DateTime(2026, 1, 2),
        current: false,
      ),
    ];

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AccountSecurityScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your devices'), findsOneWidget);
    expect(find.text('iPhone 15'), findsOneWidget);
    expect(find.text('Pixel 9'), findsOneWidget);
    expect(find.text('This device'), findsOneWidget);
    expect(find.text('Sign out others'), findsOneWidget);
  });

  testWidgets(
    'signing out another device requires confirmation, then removes it from the list',
    (tester) async {
      final container = await createTestContainer(signedIn: true);
      addTearDown(container.dispose);
      final fakeRepo =
          container.read(authRepositoryProvider) as FakeAuthRepository;
      fakeRepo.sessions = [
        DeviceSession(
          id: 'family-current',
          deviceName: 'iPhone 15',
          platform: 'ios',
          createdAt: DateTime(2026, 1, 1),
          lastUsedAt: DateTime(2026, 1, 2),
          current: true,
        ),
        DeviceSession(
          id: 'family-other',
          deviceName: 'Pixel 9',
          platform: 'android',
          createdAt: DateTime(2026, 1, 1),
          lastUsedAt: DateTime(2026, 1, 2),
          current: false,
        ),
      ];

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AccountSecurityScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await scrollUntilFound(tester, find.text('Pixel 9'));

      await tester.tap(find.widgetWithIcon(IconButton, Icons.logout).last);
      await tester.pumpAndSettle();

      expect(find.text('Sign out of Pixel 9?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastRevokedSessionId, 'family-other');
      expect(find.text('Pixel 9'), findsNothing);
      // Signing out another device never touches this session.
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.authenticated,
      );
    },
  );

  testWidgets(
    'sign out others revokes every non-current device and shows a confirmation',
    (tester) async {
      final container = await createTestContainer(signedIn: true);
      addTearDown(container.dispose);
      final fakeRepo =
          container.read(authRepositoryProvider) as FakeAuthRepository;
      fakeRepo.sessions = [
        DeviceSession(
          id: 'family-current',
          deviceName: 'iPhone 15',
          platform: 'ios',
          createdAt: DateTime(2026, 1, 1),
          lastUsedAt: DateTime(2026, 1, 2),
          current: true,
        ),
        DeviceSession(
          id: 'family-other',
          deviceName: 'Pixel 9',
          platform: 'android',
          createdAt: DateTime(2026, 1, 1),
          lastUsedAt: DateTime(2026, 1, 2),
          current: false,
        ),
      ];

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AccountSecurityScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await scrollUntilFound(tester, find.text('Sign out others'));

      await tester.tap(find.text('Sign out others'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Sign out others').last);
      await tester.pumpAndSettle();

      expect(fakeRepo.revokeOtherSessionsCalled, isTrue);
      expect(find.text('Pixel 9'), findsNothing);
      expect(find.textContaining('Signed out 1 other device'), findsOneWidget);
      // The "Sign out others" action disappears once there's nothing left to revoke.
      expect(find.text('Sign out others'), findsNothing);
    },
  );

  testWidgets(
    'signing out this device from the devices list warns first, then signs out locally',
    (tester) async {
      final container = await createTestContainer(signedIn: true);
      addTearDown(container.dispose);
      final fakeRepo =
          container.read(authRepositoryProvider) as FakeAuthRepository;
      fakeRepo.sessions = [
        DeviceSession(
          id: 'family-current',
          deviceName: 'iPhone 15',
          platform: 'ios',
          createdAt: DateTime(2026, 1, 1),
          lastUsedAt: DateTime(2026, 1, 2),
          current: true,
        ),
      ];

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AccountSecurityScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await scrollUntilFound(tester, find.text('iPhone 15'));

      await tester.tap(find.widgetWithIcon(IconButton, Icons.logout).last);
      await tester.pumpAndSettle();

      expect(find.text('Sign out of this device?'), findsOneWidget);
      expect(
        find.textContaining("device you're using right now"),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(fakeRepo.loggedOutCalled, isTrue);
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.unauthenticated,
      );
    },
  );

  testWidgets('navigates to the Delete account screen', (tester) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AccountSecurityScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await scrollUntilFound(tester, find.text('Delete my account'));

    await tester.tap(find.text('Delete my account'));
    await tester.pumpAndSettle();

    expect(find.byType(DeleteAccountScreen), findsOneWidget);
  });
}
