import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/messages/presentation/providers/conversations_controller.dart';

import '../../helpers/fake_messages_repository.dart';

void main() {
  test('loads conversations and sums unread counts on construction', () async {
    final repository = FakeMessagesRepository(
      conversations: [
        sampleConversation(id: 'conv-1', unreadCount: 2),
        sampleConversation(
          id: 'conv-2',
          otherUserId: 'friend-2',
          unreadCount: 3,
        ),
      ],
    );
    final controller = ConversationsController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.conversations, hasLength(2));
    expect(controller.state.unreadCount, 5);
    expect(controller.state.isLoading, isFalse);
  });

  test(
    'startConversation reuses an existing conversation with that recipient',
    () async {
      final repository = FakeMessagesRepository(
        conversations: [
          sampleConversation(id: 'conv-1', otherUserId: 'friend-1'),
        ],
      );
      final controller = ConversationsController(repository: repository);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      final conversation = await controller.startConversation('friend-1');

      expect(conversation.id, 'conv-1');
      expect(controller.state.conversations, hasLength(1));
    },
  );

  test(
    'startConversation creates a new conversation for a new recipient',
    () async {
      final repository = FakeMessagesRepository();
      final controller = ConversationsController(repository: repository);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      final conversation = await controller.startConversation('friend-9');

      expect(conversation.otherUserId, 'friend-9');
      expect(controller.state.conversations, hasLength(1));
    },
  );

  test('setMuted updates the conversation and refreshes', () async {
    final repository = FakeMessagesRepository(
      conversations: [sampleConversation(id: 'conv-1')],
    );
    final controller = ConversationsController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.setMuted('conv-1', true);

    expect(controller.state.conversations.single.isMuted, isTrue);
  });

  test('deleteForSelf removes the conversation from the list', () async {
    final repository = FakeMessagesRepository(
      conversations: [sampleConversation(id: 'conv-1')],
    );
    final controller = ConversationsController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.deleteForSelf('conv-1');

    expect(controller.state.conversations, isEmpty);
  });
}
