import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/support/presentation/screens/support_screen.dart';

import '../../helpers/fake_support_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows an honest empty state with no tickets', (tester) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SupportScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('No support tickets yet'), findsOneWidget);
  });

  testWidgets('lists a ticket with its category and status', (tester) async {
    final repository = FakeSupportRepository(
      tickets: [sampleTicket(subject: 'Charged twice')],
    );
    final container = await createTestContainer(
      signedIn: true,
      supportRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SupportScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Charged twice'), findsOneWidget);
    expect(find.textContaining('Bug report'), findsOneWidget);
  });
}
