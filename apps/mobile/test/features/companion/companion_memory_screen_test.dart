import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/companion/presentation/screens/companion_memory_screen.dart';

import '../../helpers/fake_companion_memory_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows an honest empty state with nothing remembered yet', (
    tester,
  ) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CompanionMemoryScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Nothing remembered yet'), findsOneWidget);
  });

  testWidgets('lists a remembered note with its category and creation date', (
    tester,
  ) async {
    final repository = FakeCompanionMemoryRepository(
      notes: [sampleMemoryNote(value: 'Training for a half marathon.')],
    );
    final container = await createTestContainer(
      signedIn: true,
      companionMemoryRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CompanionMemoryScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Training for a half marathon.'), findsOneWidget);
    expect(find.textContaining('Goal'), findsOneWidget);
    expect(find.text('Clear all memory'), findsOneWidget);
  });

  testWidgets('deleting a single note removes only that one', (tester) async {
    final repository = FakeCompanionMemoryRepository(
      notes: [
        sampleMemoryNote(id: 'note-1', value: 'Training for a half marathon.'),
        sampleMemoryNote(id: 'note-2', value: 'Has access to: dumbbells.'),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      companionMemoryRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CompanionMemoryScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.byTooltip('Forget this').first);
    await pumpForAsyncSettle(tester);

    expect(find.text('Training for a half marathon.'), findsNothing);
    expect(find.text('Has access to: dumbbells.'), findsOneWidget);
  });

  testWidgets(
    'clearing memory requires confirmation and then empties the list',
    (tester) async {
      final repository = FakeCompanionMemoryRepository(
        notes: [sampleMemoryNote(value: 'Training for a half marathon.')],
      );
      final container = await createTestContainer(
        signedIn: true,
        companionMemoryRepository: repository,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CompanionMemoryScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      await tester.tap(find.text('Clear all memory'));
      await pumpForAsyncSettle(tester);

      expect(find.text('Clear companion memory?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Clear memory'));
      await pumpForAsyncSettle(tester);

      expect(find.text('Nothing remembered yet'), findsOneWidget);
      expect(await repository.fetchNotes(), isEmpty);
    },
  );

  testWidgets('cancelling the confirmation dialog keeps the notes intact', (
    tester,
  ) async {
    final repository = FakeCompanionMemoryRepository(
      notes: [sampleMemoryNote(value: 'Training for a half marathon.')],
    );
    final container = await createTestContainer(
      signedIn: true,
      companionMemoryRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CompanionMemoryScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Clear all memory'));
    await pumpForAsyncSettle(tester);
    await tester.tap(find.text('Cancel'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Training for a half marathon.'), findsOneWidget);
    expect(await repository.fetchNotes(), isNotEmpty);
  });
}
