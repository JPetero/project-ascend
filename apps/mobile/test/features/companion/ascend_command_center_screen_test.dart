import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/entitlements/capability.dart';
import 'package:mobile/features/companion/presentation/providers/companion_chat_controller.dart';
import 'package:mobile/features/companion/presentation/providers/companion_voice_controller.dart';
import 'package:mobile/features/companion/presentation/screens/ascend_command_center_screen.dart';

import '../../helpers/fake_speech_to_text_service.dart';
import '../../helpers/fake_subscription_status_repository.dart';
import '../../helpers/fake_text_to_speech_service.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxTries = 60,
}) async {
  for (var i = 0; i < maxTries; i++) {
    if (condition()) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets(
    'a Free-tier user tapping the mic sees an upgrade prompt, never starts listening',
    (tester) async {
      final speechToText = FakeSpeechToTextService();
      final container = await createTestContainer(
        signedIn: true,
        speechToTextService: speechToText,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AscendCommandCenterScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      await tester.tap(find.byTooltip('Voice input (Premium)'));
      await pumpForAsyncSettle(tester);

      expect(find.text('Voice conversation is Premium'), findsOneWidget);
      expect(speechToText.initializeCallCount, 0);
    },
  );

  testWidgets(
    'a Premium user can tap the mic, speak, and have the transcript sent as a message',
    (tester) async {
      final speechToText = FakeSpeechToTextService();
      final container = await createTestContainer(
        signedIn: true,
        speechToTextService: speechToText,
        subscriptionStatusRepository: FakeSubscriptionStatusRepository(
          tier: PlanTier.premium,
        ),
      );
      addTearDown(container.dispose);
      container.listen(companionChatControllerProvider, (_, _) {});
      container.listen(companionVoiceControllerProvider, (_, _) {});

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AscendCommandCenterScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      await tester.tap(find.byTooltip('Voice input'));
      await pumpForAsyncSettle(tester);

      expect(speechToText.startListeningCallCount, 1);
      expect(find.text('Listening…'), findsOneWidget);

      speechToText.emitResult('log a meal', isFinal: true);
      await _pumpUntil(
        tester,
        () =>
            container.read(companionChatControllerProvider).messages.length >=
            2,
      );

      final messages = container.read(companionChatControllerProvider).messages;
      expect(messages.first.text, 'log a meal');
      expect(messages.first.isFromUser, isTrue);

      // Drain sendMessage's trailing "return to idle" timer.
      await tester.pump(const Duration(milliseconds: 700));
    },
  );

  testWidgets(
    'toggling speak-replies on a Premium account changes the AppBar icon',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        subscriptionStatusRepository: FakeSubscriptionStatusRepository(
          tier: PlanTier.premium,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AscendCommandCenterScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

      await tester.tap(find.byTooltip('Speak replies aloud (Premium)'));
      await pumpForAsyncSettle(tester);

      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'a reply is spoken aloud when speak-replies is enabled',
    (tester) async {
      final textToSpeech = FakeTextToSpeechService();
      final container = await createTestContainer(
        signedIn: true,
        textToSpeechService: textToSpeech,
        subscriptionStatusRepository: FakeSubscriptionStatusRepository(
          tier: PlanTier.premium,
        ),
      );
      addTearDown(container.dispose);
      container.listen(companionChatControllerProvider, (_, _) {});
      container.listen(companionVoiceControllerProvider, (_, _) {});

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AscendCommandCenterScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      await tester.tap(find.byTooltip('Speak replies aloud (Premium)'));
      await pumpForAsyncSettle(tester);

      final chatController = container.read(
        companionChatControllerProvider.notifier,
      );
      // sendMessage uses real Future.delayed timers under the fake test
      // clock — same reasoning as companion_chat_controller_test.dart's
      // pumpUntil helper.
      // ignore: unawaited_futures
      chatController.sendMessage('hello');
      await _pumpUntil(
        tester,
        () =>
            container.read(companionChatControllerProvider).messages.length >=
            2,
      );
      await tester.pump(const Duration(milliseconds: 700));

      expect(textToSpeech.spoken, hasLength(1));
    },
  );
}
