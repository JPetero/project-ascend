import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/messages/domain/conversation.dart';
import 'package:mobile/features/messages/presentation/providers/conversation_detail_controller.dart';

import '../../helpers/fake_messages_repository.dart';

void main() {
  test(
    'loads messages oldest-first and picks up the conversation status',
    () async {
      final repository = FakeMessagesRepository(
        conversations: [
          sampleConversation(id: 'conv-1', status: ConversationStatus.pending),
        ],
      );
      repository.messagesByConversation['conv-1'] = [
        sampleDirectMessage(id: 'm-1', createdAt: DateTime.utc(2026, 8, 7, 9)),
        sampleDirectMessage(id: 'm-2', createdAt: DateTime.utc(2026, 8, 7, 10)),
      ];
      final controller = ConversationDetailController(
        repository: repository,
        conversationId: 'conv-1',
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.messages.map((m) => m.id), ['m-1', 'm-2']);
      expect(controller.state.status, ConversationStatus.pending);
      expect(controller.state.isLoading, isFalse);
    },
  );

  test(
    'sendMessage appends the new message and clears the sending flag',
    () async {
      final repository = FakeMessagesRepository(
        conversations: [sampleConversation(id: 'conv-1')],
      );
      final controller = ConversationDetailController(
        repository: repository,
        conversationId: 'conv-1',
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      final sent = await controller.sendMessage('Hello!');

      expect(sent, isTrue);
      expect(repository.lastSentBody, 'Hello!');
      expect(controller.state.messages, hasLength(1));
      expect(controller.state.isSending, isFalse);
    },
  );

  test(
    'sendMessage rejects a blank body without calling the repository',
    () async {
      final repository = FakeMessagesRepository(
        conversations: [sampleConversation(id: 'conv-1')],
      );
      final controller = ConversationDetailController(
        repository: repository,
        conversationId: 'conv-1',
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      final sent = await controller.sendMessage('   ');

      expect(sent, isFalse);
      expect(repository.lastSentBody, isNull);
    },
  );

  test('accept transitions a pending request to accepted', () async {
    final repository = FakeMessagesRepository(
      conversations: [
        sampleConversation(
          id: 'conv-1',
          status: ConversationStatus.pending,
          initiatorId: 'friend-1',
        ),
      ],
    );
    final controller = ConversationDetailController(
      repository: repository,
      conversationId: 'conv-1',
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.accept();

    expect(controller.state.status, ConversationStatus.accepted);
  });

  test('decline transitions a pending request to declined', () async {
    final repository = FakeMessagesRepository(
      conversations: [
        sampleConversation(
          id: 'conv-1',
          status: ConversationStatus.pending,
          initiatorId: 'friend-1',
        ),
      ],
    );
    final controller = ConversationDetailController(
      repository: repository,
      conversationId: 'conv-1',
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.decline();

    expect(controller.state.status, ConversationStatus.declined);
  });

  test('isInitiator is true only for the participant who started it', () async {
    final repository = FakeMessagesRepository(
      conversations: [sampleConversation(id: 'conv-1', initiatorId: 'me')],
    );
    final controller = ConversationDetailController(
      repository: repository,
      conversationId: 'conv-1',
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.isInitiator('me'), isTrue);
    expect(controller.state.isInitiator('friend-1'), isFalse);
  });
}
