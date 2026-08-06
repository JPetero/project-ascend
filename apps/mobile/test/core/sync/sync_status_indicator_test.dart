import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/sync/sync_status.dart';
import 'package:mobile/core/sync/sync_status_indicator.dart';
import 'package:mobile/core/sync/sync_providers.dart';

void main() {
  testWidgets('renders nothing when caught up', (tester) async {
    final container = ProviderContainer(
      overrides: [
        syncStatusProvider.overrideWithValue(const SyncStatus.idle()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: SyncStatusIndicator())),
      ),
    );

    expect(find.byType(SyncStatusIndicator), findsOneWidget);
    expect(find.textContaining('sync', findRichText: true), findsNothing);
  });

  testWidgets('shows a pending count with no retry action', (tester) async {
    final container = ProviderContainer(
      overrides: [
        syncStatusProvider.overrideWithValue(
          const SyncStatus(isSyncing: false, pendingCount: 2, failedCount: 0),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: SyncStatusIndicator())),
      ),
    );

    expect(find.text('2 changes waiting to sync'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('shows a failed count with a retry action', (tester) async {
    final container = ProviderContainer(
      overrides: [
        syncStatusProvider.overrideWithValue(
          const SyncStatus(isSyncing: false, pendingCount: 0, failedCount: 1),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: SyncStatusIndicator())),
      ),
    );

    expect(find.text('1 change needs attention'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
