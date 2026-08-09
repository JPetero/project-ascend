import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/companion/domain/companion_conversation.dart';
import 'package:mobile/features/companion/presentation/providers/companion_conversations_controller.dart';

import '../../helpers/fake_companion_conversations_repository.dart';

void main() {
  test('loads the caller\'s saved conversations on construction', () async {
    final repository = FakeCompanionConversationsRepository(
      conversations: [
        sampleConversation(
          id: 'conversation-1',
          lastMessagePreview: 'How was your run today?',
        ),
      ],
    );
    final controller = CompanionConversationsController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.isLoading, isFalse);
    expect(
      controller.state.conversations.single.lastMessagePreview,
      'How was your run today?',
    );
  });

  test('rename() persists the new title and is reflected in state', () async {
    final repository = FakeCompanionConversationsRepository(
      conversations: [sampleConversation(id: 'conversation-1')],
    );
    final controller = CompanionConversationsController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.rename('conversation-1', 'Week 1 planning');

    expect(controller.state.conversations.single.title, 'Week 1 planning');
    expect(
      (await repository.fetchConversation('conversation-1')).title,
      'Week 1 planning',
    );
  });

  test(
    'delete() removes just that one conversation and is reflected in state',
    () async {
      final repository = FakeCompanionConversationsRepository(
        conversations: [
          sampleConversation(id: 'conversation-1'),
          sampleConversation(id: 'conversation-2'),
        ],
      );
      final controller = CompanionConversationsController(
        repository: repository,
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      await controller.delete('conversation-1');

      expect(controller.state.conversations.map((c) => c.id), [
        'conversation-2',
      ]);
      expect((await repository.fetchConversations()).map((c) => c.id), [
        'conversation-2',
      ]);
    },
  );

  test('clear() empties the conversations and is reflected in state', () async {
    final repository = FakeCompanionConversationsRepository(
      conversations: [sampleConversation(id: 'conversation-1')],
    );
    final controller = CompanionConversationsController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.clear();

    expect(controller.state.conversations, isEmpty);
    expect(await repository.fetchConversations(), isEmpty);
  });

  test('refresh() surfaces a fetch failure without throwing', () async {
    final controller = CompanionConversationsController(
      repository: _ThrowingCompanionConversationsRepository(),
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.error, isNotNull);
  });
}

class _ThrowingCompanionConversationsRepository
    extends FakeCompanionConversationsRepository {
  @override
  Future<List<CompanionConversationSummary>> fetchConversations() async =>
      throw Exception('network error');
}
