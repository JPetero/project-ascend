import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/companion/presentation/screens/companion_conversations_screen.dart';

import '../../helpers/fake_companion_conversations_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows an honest empty state with nothing saved yet', (
    tester,
  ) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CompanionConversationsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('No saved conversations yet'), findsOneWidget);
  });

  testWidgets('lists a saved conversation with its companion and date', (
    tester,
  ) async {
    final repository = FakeCompanionConversationsRepository(
      conversations: [
        sampleConversation(
          id: 'conversation-1',
          lastMessagePreview: 'How was your run today?',
        ),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      companionConversationsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CompanionConversationsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('How was your run today?'), findsOneWidget);
    expect(find.textContaining('Atlas ·'), findsOneWidget);
    expect(find.text('Clear all conversation history'), findsOneWidget);
  });

  testWidgets('renaming a conversation updates the list', (tester) async {
    final repository = FakeCompanionConversationsRepository(
      conversations: [
        sampleConversation(
          id: 'conversation-1',
          lastMessagePreview: 'How was your run today?',
        ),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      companionConversationsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CompanionConversationsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await pumpForAsyncSettle(tester);
    await tester.tap(find.text('Rename'));
    await pumpForAsyncSettle(tester);

    await tester.enterText(find.byType(TextField), 'Week 1 planning');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Week 1 planning'), findsOneWidget);
  });

  testWidgets('deleting a single conversation removes only that one', (
    tester,
  ) async {
    final repository = FakeCompanionConversationsRepository(
      conversations: [
        sampleConversation(
          id: 'conversation-1',
          lastMessagePreview: 'How was your run today?',
        ),
        sampleConversation(
          id: 'conversation-2',
          lastMessagePreview: 'Any tips on recovery?',
        ),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      companionConversationsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CompanionConversationsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await pumpForAsyncSettle(tester);
    await tester.tap(find.text('Delete'));
    await pumpForAsyncSettle(tester);

    expect(find.text('How was your run today?'), findsNothing);
    expect(find.text('Any tips on recovery?'), findsOneWidget);
  });

  testWidgets(
    'clearing history requires confirmation and then empties the list',
    (tester) async {
      final repository = FakeCompanionConversationsRepository(
        conversations: [
          sampleConversation(
            id: 'conversation-1',
            lastMessagePreview: 'How was your run today?',
          ),
        ],
      );
      final container = await createTestContainer(
        signedIn: true,
        companionConversationsRepository: repository,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CompanionConversationsScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      await tester.tap(find.text('Clear all conversation history'));
      await pumpForAsyncSettle(tester);

      expect(find.text('Clear all conversation history?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Clear history'));
      await pumpForAsyncSettle(tester);

      expect(find.text('No saved conversations yet'), findsOneWidget);
      expect(await repository.fetchConversations(), isEmpty);
    },
  );

  testWidgets('cancelling the clear confirmation keeps history intact', (
    tester,
  ) async {
    final repository = FakeCompanionConversationsRepository(
      conversations: [
        sampleConversation(
          id: 'conversation-1',
          lastMessagePreview: 'How was your run today?',
        ),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      companionConversationsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CompanionConversationsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Clear all conversation history'));
    await pumpForAsyncSettle(tester);
    await tester.tap(find.text('Cancel'));
    await pumpForAsyncSettle(tester);

    expect(find.text('How was your run today?'), findsOneWidget);
    expect(await repository.fetchConversations(), isNotEmpty);
  });
}
