import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';
import 'package:mobile/features/dashboard/presentation/screens/dashboard_screen.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  // Account section sits below the fold, same scroll requirement as
  // dashboard_community_cards_test.dart.
  Future<void> scrollUntilFound(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }

  group('Dashboard Account & Security — Build Session 9 Part 4', () {
    testWidgets('shows a verify-email banner for an unverified account', (
      tester,
    ) async {
      final container = await createTestContainer(signedIn: true);
      addTearDown(container.dispose);
      final fakeRepo =
          container.read(authRepositoryProvider) as FakeAuthRepository;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await scrollUntilFound(tester, find.text('Verify your email'));

      expect(find.text('Verify your email'), findsOneWidget);

      await tester.tap(find.text('Resend'));
      await tester.pumpAndSettle();

      expect(fakeRepo.resendVerificationCalled, isTrue);
    });

    testWidgets('offers a Change password entry point in the Account section', (
      tester,
    ) async {
      final container = await createTestContainer(signedIn: true);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await scrollUntilFound(tester, find.text('Change password'));

      expect(find.text('Change password'), findsOneWidget);
    });
  });
}
