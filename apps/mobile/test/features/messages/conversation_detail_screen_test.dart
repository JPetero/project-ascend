import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/app_exception.dart';
import 'package:mobile/features/messages/domain/conversation.dart';
import 'package:mobile/features/messages/presentation/screens/conversation_detail_screen.dart';

import '../../helpers/fake_messages_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets(
    'a stale or unauthorized conversation target shows a safe unavailable state',
    (tester) async {
      final repository = FakeMessagesRepository()
        ..getMessagesError = const AppException(
          message: 'Conversation not found.',
        );
      final container = await createTestContainer(
        signedIn: true,
        messagesRepository: repository,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ConversationDetailScreen(conversationId: 'stale-conv'),
          ),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.text('Conversation not available'), findsOneWidget);
      expect(find.text('Conversation not found.'), findsOneWidget);
      // Never falls through to the brand-new-conversation empty state.
      expect(find.text('Say hello'), findsNothing);
    },
  );

  testWidgets('shows existing messages and sends a new one', (tester) async {
    final repository = FakeMessagesRepository(
      conversations: [
        sampleConversation(
          id: 'conv-1',
          initiatorId: 'user-1',
          otherUserId: 'friend-1',
        ),
      ],
    );
    repository.messagesByConversation['conv-1'] = [
      sampleDirectMessage(id: 'm-1', senderId: 'friend-1', body: 'Hey!'),
    ];
    final container = await createTestContainer(
      signedIn: true,
      messagesRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ConversationDetailScreen(
            conversationId: 'conv-1',
            otherUserId: 'friend-1',
          ),
        ),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Hey!'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Hi back');
    await tester.tap(find.byIcon(Icons.send));
    await pumpForAsyncSettle(tester);

    expect(repository.lastSentBody, 'Hi back');
    expect(find.text('Hi back'), findsOneWidget);
  });

  testWidgets('a received pending request shows accept/decline actions', (
    tester,
  ) async {
    final repository = FakeMessagesRepository(
      conversations: [
        sampleConversation(
          id: 'conv-1',
          status: ConversationStatus.pending,
          initiatorId: 'friend-1',
          otherUserId: 'friend-1',
        ),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      messagesRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ConversationDetailScreen(
            conversationId: 'conv-1',
            otherUserId: 'friend-1',
          ),
        ),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('This is a message request.'), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await pumpForAsyncSettle(tester);

    expect(find.text('This is a message request.'), findsNothing);
  });

  testWidgets('waiting on a sent request shows an informational banner', (
    tester,
  ) async {
    final repository = FakeMessagesRepository(
      conversations: [
        sampleConversation(
          id: 'conv-1',
          status: ConversationStatus.pending,
          initiatorId: 'user-1',
          otherUserId: 'friend-1',
        ),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      messagesRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ConversationDetailScreen(
            conversationId: 'conv-1',
            otherUserId: 'friend-1',
          ),
        ),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.textContaining('Message request sent'), findsOneWidget);
  });
}
