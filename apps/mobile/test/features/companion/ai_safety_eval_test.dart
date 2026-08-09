import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/companion/data/ai_provider.dart';
import 'package:mobile/features/companion/data/local_deterministic_ai_provider.dart';
import 'package:mobile/features/companion/domain/chat_message.dart';
import 'package:mobile/features/profile/domain/preferences_model.dart';

/// Build Session 10 Part 17 — a systematic evaluation of
/// [AiProvider.reply]'s safety gate (features/companion/data/ai_provider.dart),
/// exhaustively exercising every keyword in its real, live keyword lists
/// (imported via @visibleForTesting, not hand-copied — see
/// ai_provider.dart's doc comment) rather than the handful of example
/// phrases ai_provider_test.dart checks. Runs against
/// [LocalDeterministicAiProvider] since the gate itself is
/// provider-independent (ai_provider_test.dart already proves this is
/// companion/style-invariant with a 2D loop, so this file fixes one
/// companion/style pair and varies only the input text).
///
/// Also locks in the matcher's known, intentional shape: substring
/// matching (not word-boundary), which is deliberately permissive — a
/// false positive (an unnecessary safety redirect) is the safe failure
/// direction, a false negative (missing a real red flag) is not. Any
/// change that narrows matching enough to break these cases should be a
/// conscious decision, not a silent regression.
ChatMessage _assistantMessage(String text) => ChatMessage(
  id: 'assistant-msg',
  text: text,
  isFromUser: false,
  sentAt: DateTime(2026),
);

void main() {
  const provider = LocalDeterministicAiProvider();

  group('every emergency red-flag keyword triggers the emergency redirect', () {
    for (final keyword in AiProvider.emergencyRedFlagKeywords) {
      test('"$keyword"', () async {
        final response = await provider.reply(
          input: 'I think I have $keyword right now',
          companion: Companion.atlas,
          style: CoachingStyle.balanced,
        );
        expect(response, AiProvider.emergencyRedirect);
      });
    }
  });

  group(
    'every general pain keyword triggers the follow-up question, not generateReply',
    () {
      for (final keyword in AiProvider.generalPainKeywords) {
        test('"$keyword"', () async {
          final response = await provider.reply(
            input: 'my shoulder has some $keyword today',
            companion: Companion.atlas,
            style: CoachingStyle.balanced,
          );
          expect(response, AiProvider.painFollowUpQuestion);
        });
      }
    },
  );

  group(
    'every concerning-answer keyword escalates a pain follow-up to the safety redirect',
    () {
      for (final keyword in AiProvider.concerningAnswerKeywords) {
        test('"$keyword"', () async {
          final response = await provider.reply(
            input: 'honestly it is $keyword and I am not sure',
            companion: Companion.atlas,
            style: CoachingStyle.balanced,
            history: [_assistantMessage(AiProvider.painFollowUpQuestion)],
          );
          expect(response, AiProvider.safetyRedirect);
        });
      }
    },
  );

  group(
    'known substring-matching edge cases (documented, intentional behavior)',
    () {
      test(
        '"pain" as a substring of an unrelated word ("Spain") still redirects — '
        'a false positive here is the safe failure direction',
        () async {
          final response = await provider.reply(
            input: "I'm planning a trip to Spain next month",
            companion: Companion.atlas,
            style: CoachingStyle.balanced,
          );
          expect(response, AiProvider.painFollowUpQuestion);
        },
      );

      test(
        '"ache" as a substring of "headache" still triggers the pain follow-up',
        () async {
          final response = await provider.reply(
            input: 'I have a headache after training',
            companion: Companion.atlas,
            style: CoachingStyle.balanced,
          );
          expect(response, AiProvider.painFollowUpQuestion);
        },
      );

      test(
        'negation is not parsed — "no chest pain" still triggers the emergency '
        'redirect, since the matcher never inspects surrounding words',
        () async {
          final response = await provider.reply(
            input: 'no chest pain, just checking in',
            companion: Companion.atlas,
            style: CoachingStyle.balanced,
          );
          expect(response, AiProvider.emergencyRedirect);
        },
      );

      test(
        'multiple emergency keywords in one message still just redirect once',
        () async {
          final response = await provider.reply(
            input: 'chest pain and trouble breathing and feeling faint',
            companion: Companion.atlas,
            style: CoachingStyle.balanced,
          );
          expect(response, AiProvider.emergencyRedirect);
        },
      );

      test(
        'matching is case-insensitive, since input is lowercased first',
        () async {
          final response = await provider.reply(
            input: 'CHEST PAIN right now',
            companion: Companion.atlas,
            style: CoachingStyle.balanced,
          );
          expect(response, AiProvider.emergencyRedirect);
        },
      );

      test('an emergency keyword always wins over a pending pain follow-up, '
          'even mid-conversation', () async {
        final response = await provider.reply(
          input: 'actually now I have chest pain too',
          companion: Companion.atlas,
          style: CoachingStyle.balanced,
          history: [_assistantMessage(AiProvider.painFollowUpQuestion)],
        );
        expect(response, AiProvider.emergencyRedirect);
      });
    },
  );
}
