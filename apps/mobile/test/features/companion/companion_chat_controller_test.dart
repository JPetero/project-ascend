import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/companion/data/ai_provider.dart';
import 'package:mobile/features/companion/domain/chat_message.dart';
import 'package:mobile/features/companion/presentation/providers/companion_chat_controller.dart';
import 'package:mobile/features/profile/domain/preferences_model.dart';

import '../../helpers/test_provider_scope.dart';

/// A stand-in "future live provider" — proves the controller genuinely
/// doesn't care which [AiProvider] is plugged in.
class _FakeProvider extends AiProvider {
  const _FakeProvider();

  @override
  Future<String> generateReply({
    required String input,
    required Companion companion,
    required CoachingStyle style,
    List<ChatMessage> history = const [],
  }) async {
    return 'FAKE PROVIDER REPLY: $input';
  }
}

void main() {
  /// [CompanionChatController.sendMessage] uses real `Future.delayed`
  /// timers (a simulated "thinking" latency) rather than only awaiting
  /// repository calls, so — unlike workout_session_controller_test.dart's
  /// pattern — it must never be awaited directly in a test: under
  /// `AutomatedTestWidgetsFlutterBinding`'s fake clock, those timers
  /// only fire while `tester.pump(duration)` is actively advancing time.
  /// Call `sendMessage` with `unawaited` and drive it to completion with
  /// this helper instead.
  Future<void> pumpUntil(WidgetTester tester, bool Function() condition) async {
    for (var i = 0; i < 60; i++) {
      if (condition()) return;
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets(
    'sends a message and receives a reply from the default local provider',
    (tester) async {
      final container = await createTestContainer();
      addTearDown(container.dispose);
      // companionChatControllerProvider is `.autoDispose`; a bare
      // `container.read` doesn't keep it alive once the synchronous
      // read returns, which would tear the controller down mid-
      // `sendMessage`. `container.listen` holds it alive for the test.
      container.listen(companionChatControllerProvider, (_, _) {});
      final controller = container.read(
        companionChatControllerProvider.notifier,
      );

      unawaited(controller.sendMessage('hello'));
      await pumpUntil(
        tester,
        () =>
            container.read(companionChatControllerProvider).messages.length >=
            2,
      );

      final messages = container.read(companionChatControllerProvider).messages;
      expect(messages, hasLength(2));
      expect(messages.first.isFromUser, isTrue);
      expect(messages.last.isFromUser, isFalse);
      expect(messages.last.text, contains('Atlas'));

      // Drains sendMessage's trailing "return to idle" timer so no timer
      // is still pending when the test ends.
      await tester.pump(const Duration(milliseconds: 700));
    },
  );

  testWidgets(
    'a red-flag message returns the shared emergency redirect even with a '
    'swapped-in provider that would otherwise answer differently',
    (tester) async {
      final container = await createTestContainer(
        aiProvider: const _FakeProvider(),
      );
      addTearDown(container.dispose);
      // See the "hello" test above for why this listen is needed.
      container.listen(companionChatControllerProvider, (_, _) {});
      final controller = container.read(
        companionChatControllerProvider.notifier,
      );

      unawaited(controller.sendMessage('I have chest pain'));
      await pumpUntil(
        tester,
        () =>
            container.read(companionChatControllerProvider).messages.length >=
            2,
      );

      final reply = container
          .read(companionChatControllerProvider)
          .messages
          .last;
      expect(reply.text, AiProvider.emergencyRedirect);
      expect(reply.text, isNot(contains('FAKE PROVIDER REPLY')));

      await tester.pump(const Duration(milliseconds: 700));
    },
  );

  testWidgets(
    'a general pain mention asks a clarifying question first, then applies '
    'the shared safety rule to the follow-up answer — even with a '
    'swapped-in provider that would otherwise answer differently',
    (tester) async {
      final container = await createTestContainer(
        aiProvider: const _FakeProvider(),
      );
      addTearDown(container.dispose);
      // See the "hello" test above for why this listen is needed.
      container.listen(companionChatControllerProvider, (_, _) {});
      final controller = container.read(
        companionChatControllerProvider.notifier,
      );

      unawaited(controller.sendMessage('my knee hurts'));
      await pumpUntil(
        tester,
        () =>
            container.read(companionChatControllerProvider).messages.length >=
            2,
      );
      final followUp = container
          .read(companionChatControllerProvider)
          .messages
          .last;
      expect(followUp.text, isNot(contains('FAKE PROVIDER REPLY')));
      expect(followUp.text, isNot(AiProvider.safetyRedirect));

      await tester.pump(const Duration(milliseconds: 700));

      unawaited(controller.sendMessage('it has been getting worse for weeks'));
      await pumpUntil(
        tester,
        () =>
            container.read(companionChatControllerProvider).messages.length >=
            4,
      );
      final reply = container
          .read(companionChatControllerProvider)
          .messages
          .last;
      expect(reply.text, AiProvider.safetyRedirect);
      expect(reply.text, isNot(contains('FAKE PROVIDER REPLY')));

      await tester.pump(const Duration(milliseconds: 700));
    },
  );

  testWidgets(
    'swapping the provider changes non-safety replies with no controller change',
    (tester) async {
      final container = await createTestContainer(
        aiProvider: const _FakeProvider(),
      );
      addTearDown(container.dispose);
      // See the "hello" test above for why this listen is needed.
      container.listen(companionChatControllerProvider, (_, _) {});
      final controller = container.read(
        companionChatControllerProvider.notifier,
      );

      unawaited(controller.sendMessage('what should I eat today'));
      await pumpUntil(
        tester,
        () =>
            container.read(companionChatControllerProvider).messages.length >=
            2,
      );

      final reply = container
          .read(companionChatControllerProvider)
          .messages
          .last;
      expect(reply.text, 'FAKE PROVIDER REPLY: what should I eat today');

      await tester.pump(const Duration(milliseconds: 700));
    },
  );
}
