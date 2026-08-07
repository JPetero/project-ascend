import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/data_export/presentation/screens/data_export_screen.dart';

import '../../helpers/fake_data_export_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('describes what gets exported and offers an export button', (
    tester,
  ) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DataExportScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Export and share'), findsOneWidget);
  });

  testWidgets('tapping export fetches and shares the data, then confirms', (
    tester,
  ) async {
    final shareService = FakeDataExportShareService();
    final container = await createTestContainer(
      signedIn: true,
      dataExportShareService: shareService,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DataExportScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Export and share'));
    await pumpForAsyncSettle(tester);

    expect(shareService.shareCount, 1);
    expect(find.text('Your export is ready to save or send.'), findsOneWidget);
  });

  testWidgets('shows an honest error state and lets the user retry', (
    tester,
  ) async {
    final repository = FakeDataExportRepository(
      error: Exception('network down'),
    );
    final container = await createTestContainer(
      signedIn: true,
      dataExportRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DataExportScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Export and share'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Try again'), findsOneWidget);
    expect(find.textContaining('network down'), findsOneWidget);
  });
}
