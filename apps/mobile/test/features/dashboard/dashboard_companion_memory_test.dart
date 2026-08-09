import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/dashboard/presentation/screens/dashboard_screen.dart';

import '../../helpers/test_provider_scope.dart';

void main() {
  // Settings section sits below the fold, same scroll requirement as
  // dashboard_account_security_test.dart.
  Future<void> scrollUntilFound(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }

  testWidgets(
    'offers a real entry point to manage companion memory — Build Session 10 Part 15',
    (tester) async {
      final container = await createTestContainer(signedIn: true);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await scrollUntilFound(tester, find.text('Manage companion memory'));

      expect(find.text('Manage companion memory'), findsOneWidget);
    },
  );
}
