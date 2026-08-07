import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/messages/presentation/screens/conversations_screen.dart';

import '../../helpers/fake_messages_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows an honest empty state with no conversations', (
    tester,
  ) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ConversationsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('No conversations yet'), findsOneWidget);
  });

  testWidgets(
    'lists a conversation with a Request label when pending and received',
    (tester) async {
      final repository = FakeMessagesRepository(
        conversations: [
          sampleConversation(
            id: 'conv-1',
            initiatorId: 'friend-1',
            otherUserId: 'friend-1',
          ),
        ],
      );
      // Force this conversation into a received-request state.
      repository.conversations[0] = sampleConversation(
        id: 'conv-1',
        initiatorId: 'friend-1',
        otherUserId: 'friend-1',
        unreadCount: 1,
      );
      final container = await createTestContainer(
        signedIn: true,
        messagesRepository: repository,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ConversationsScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.text('Ascend member'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    },
  );
}
