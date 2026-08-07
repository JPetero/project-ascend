import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/companion/presentation/screens/research_mode_screen.dart';

import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets(
    'searching shows the honest "not available" state, never a fabricated answer',
    (tester) async {
      final container = await createTestContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ResearchModeScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      await tester.enterText(find.byType(TextFormField), 'shin splints');
      await tester.tap(find.byTooltip('Search'));
      await pumpForAsyncSettle(tester);

      expect(find.text('Research mode is on its way'), findsOneWidget);
      expect(find.textContaining('Nothing here is invented'), findsOneWidget);
    },
  );

  testWidgets('an empty query does nothing', (tester) async {
    final container = await createTestContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ResearchModeScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.byTooltip('Search'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Research mode is on its way'), findsNothing);
  });
}
