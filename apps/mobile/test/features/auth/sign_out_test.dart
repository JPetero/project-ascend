import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';
import 'package:mobile/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:mobile/features/profile/domain/profile_model.dart';

import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('signing out clears the session and returns to unauthenticated', (
    tester,
  ) async {
    final container = await createTestContainer(
      signedIn: true,
      initialProfile: const ProfileModel(
        firstName: 'Ada',
        languageCode: 'en',
        timezone: 'UTC',
        unitSystem: UnitSystem.metric,
        sexForCalculations: SexForCalculations.unspecified,
        onboardingCompleted: true,
        onboardingStep: 8,
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      container.read(authControllerProvider).status,
      AuthStatus.authenticated,
    );
    expect(
      await container.read(secureTokenStorageProvider).readRefreshToken(),
      isNotNull,
    );

    final signOutButton = find.widgetWithText(ElevatedButton, 'Sign out');
    await tester.scrollUntilVisible(
      signOutButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // scrollUntilVisible only requires a single pixel on-screen, which
    // can still leave the button's computed center just outside the
    // viewport (as happened once a new dashboard card pushed this
    // button further down) — ensureVisible scrolls it fully into view
    // so tap()'s center-point hit test lands on it.
    await tester.ensureVisible(signOutButton);
    await tester.pumpAndSettle();
    await tester.tap(signOutButton);
    await tester.pumpAndSettle();

    final confirmButton = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Sign out'),
    );
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(container.read(authControllerProvider).user, isNull);
    expect(
      await container.read(secureTokenStorageProvider).readRefreshToken(),
      isNull,
    );
  });
}
