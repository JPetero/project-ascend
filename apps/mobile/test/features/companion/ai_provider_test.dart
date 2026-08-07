import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/companion/data/ai_provider.dart';
import 'package:mobile/features/companion/data/local_deterministic_ai_provider.dart';
import 'package:mobile/features/companion/domain/chat_message.dart';
import 'package:mobile/features/profile/domain/preferences_model.dart';

/// A fake provider that would (if the shared safety gate didn't exist)
/// answer differently per companion — used to prove [AiProvider.reply]
/// enforces the identical-safety-content rule structurally, not by
/// convention.
class _VaryingFakeProvider extends AiProvider {
  const _VaryingFakeProvider();

  @override
  Future<String> generateReply({
    required String input,
    required Companion companion,
    required CoachingStyle style,
  }) async {
    return 'reply from ${companion.name}/${style.name}: $input';
  }
}

ChatMessage _assistantMessage(String text) => ChatMessage(
  id: 'assistant-msg',
  text: text,
  isFromUser: false,
  sentAt: DateTime(2026),
);

void main() {
  group('AiProvider.reply — red flags', () {
    test(
      'an emergency red-flag phrase always returns the emergency redirect, '
      'regardless of companion, style, or the concrete provider plugged in',
      () async {
        const provider = _VaryingFakeProvider();
        final responses = <String>{};
        for (final companion in Companion.values) {
          for (final style in CoachingStyle.values) {
            responses.add(
              await provider.reply(
                input: 'I have chest pain and feel faint',
                companion: companion,
                style: style,
              ),
            );
          }
        }

        expect(responses, {AiProvider.emergencyRedirect});
      },
    );

    test('a red flag surfaced as the answer to the pain follow-up question '
        'still escalates to the emergency redirect', () async {
      const provider = _VaryingFakeProvider();

      final response = await provider.reply(
        input: 'severe swelling and I can\'t bear weight on it',
        companion: Companion.atlas,
        style: CoachingStyle.balanced,
        history: [_assistantMessage(_painFollowUpQuestionForTest)],
      );

      expect(response, AiProvider.emergencyRedirect);
    });
  });

  group('AiProvider.reply — general pain, conversational flow', () {
    test(
      'first mention of general pain asks a clarifying question instead of '
      'jumping straight to the stock safety line, and never reaches generateReply',
      () async {
        const provider = _VaryingFakeProvider();

        final response = await provider.reply(
          input: 'my knee hurts',
          companion: Companion.atlas,
          style: CoachingStyle.balanced,
        );

        expect(response, isNot(contains('reply from')));
        expect(response, isNot(AiProvider.safetyRedirect));
        expect(response, contains('severe'));
      },
    );

    test(
      'the clarifying question is identical regardless of companion or style',
      () async {
        const provider = _VaryingFakeProvider();
        final responses = <String>{};
        for (final companion in Companion.values) {
          for (final style in CoachingStyle.values) {
            responses.add(
              await provider.reply(
                input: 'my shoulder is sore',
                companion: companion,
                style: style,
              ),
            );
          }
        }

        expect(responses, hasLength(1));
      },
    );

    test('a concerning follow-up answer (persistent/severe/unclear) escalates '
        'to the professional-evaluation redirect', () async {
      const provider = _VaryingFakeProvider();
      final followUp = await provider.reply(
        input: 'my knee hurts',
        companion: Companion.atlas,
        style: CoachingStyle.balanced,
      );

      final response = await provider.reply(
        input: 'it has been getting worse for a few weeks',
        companion: Companion.atlas,
        style: CoachingStyle.balanced,
        history: [_assistantMessage(followUp)],
      );

      expect(response, AiProvider.safetyRedirect);
    });

    test(
      'a mild, non-concerning follow-up answer gets honest general guidance, '
      'not a diagnosis and not the stock safety line',
      () async {
        const provider = _VaryingFakeProvider();
        final followUp = await provider.reply(
          input: 'my knee hurts',
          companion: Companion.atlas,
          style: CoachingStyle.balanced,
        );

        final response = await provider.reply(
          input: 'mild, started yesterday after a new leg workout',
          companion: Companion.atlas,
          style: CoachingStyle.balanced,
          history: [_assistantMessage(followUp)],
        );

        expect(response, isNot(AiProvider.safetyRedirect));
        expect(response, isNot(AiProvider.emergencyRedirect));
        expect(response, contains('rest'));
      },
    );

    test('an unrelated assistant message in history does not falsely trigger '
        'the follow-up-answer branch', () async {
      const provider = _VaryingFakeProvider();

      final response = await provider.reply(
        input: 'it has been getting worse for a few weeks',
        companion: Companion.atlas,
        style: CoachingStyle.balanced,
        history: [_assistantMessage('Hey! Ready for today\'s workout?')],
      );

      // No pain keyword in this input and no live follow-up pending —
      // falls through to generateReply.
      expect(response, contains('reply from atlas/balanced'));
    });
  });

  group('AiProvider.reply — non-safety input', () {
    test('delegates non-safety input to generateReply', () async {
      const provider = _VaryingFakeProvider();

      final response = await provider.reply(
        input: 'what should I eat',
        companion: Companion.nova,
        style: CoachingStyle.direct,
      );

      expect(response, 'reply from nova/direct: what should I eat');
    });
  });

  group('AiProvider.researchReply — default implementation', () {
    test(
      'honestly reports unavailable rather than fabricating a citation',
      () async {
        const provider = _VaryingFakeProvider();

        final answer = await provider.researchReply(
          query: 'best recovery protocol',
        );

        expect(answer.isAvailable, isFalse);
        expect(answer.sources, isEmpty);
        expect(answer.unavailableReason, isNotNull);
      },
    );
  });

  group('LocalDeterministicAiProvider', () {
    test(
      'delegates to the local deterministic dialogue for non-safety input',
      () async {
        const provider = LocalDeterministicAiProvider();

        final response = await provider.reply(
          input: 'hello',
          companion: Companion.atlas,
          style: CoachingStyle.balanced,
        );

        expect(response, contains('Atlas'));
      },
    );

    test('still runs the shared safety gate for a red-flag phrase', () async {
      const provider = LocalDeterministicAiProvider();

      final response = await provider.reply(
        input: 'severe chest pain',
        companion: Companion.atlas,
        style: CoachingStyle.balanced,
      );

      expect(response, AiProvider.emergencyRedirect);
    });

    test(
      'inherits the honest "not available" research default with no override',
      () async {
        const provider = LocalDeterministicAiProvider();

        final answer = await provider.researchReply(query: 'shin splints');

        expect(answer.isAvailable, isFalse);
      },
    );
  });
}

// Mirrors AiProvider's private follow-up question text so this test file
// can build a realistic "assistant asked, user answered" history without
// reaching into AiProvider's private members.
const _painFollowUpQuestionForTest =
    "Before I say anything else — how severe would you say it is, when did it start, and "
    'was there a specific injury (a fall, twist, or impact), or did it come on gradually?';
