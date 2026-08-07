import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/dashboard/presentation/screens/dashboard_screen.dart';

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

  testWidgets(
    'offers a single Account & Security entry point — Build Session 9 Part 5/6',
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
      await scrollUntilFound(tester, find.text('Account & Security'));

      expect(find.text('Account & Security'), findsOneWidget);
    },
  );
}
