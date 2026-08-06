import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/cardio/presentation/screens/cardio_history_screen.dart';

import '../../helpers/fake_cardio_repositories.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows an honest empty state with no cardio sessions', (
    tester,
  ) async {
    final container = await createTestContainer(
      cardioSessionRepository: FakeCardioSessionRepository(),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CardioHistoryScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('No cardio sessions yet'), findsOneWidget);
  });

  testWidgets('lists logged sessions and deletes one', (tester) async {
    final repository = FakeCardioSessionRepository(
      sessions: [sampleCardioSession],
    );
    final container = await createTestContainer(
      cardioSessionRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CardioHistoryScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Run'), findsOneWidget);
    expect(find.textContaining('30 min'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await pumpForAsyncSettle(tester);

    expect(find.text('No cardio sessions yet'), findsOneWidget);
  });
}
