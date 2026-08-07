import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/companion/data/ai_provider.dart';
import 'package:mobile/features/companion/data/local_deterministic_ai_provider.dart';
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

void main() {
  group('AiProvider.reply', () {
    test(
      'returns the identical safety redirect regardless of companion, style, '
      'or the concrete provider plugged in — never reaches generateReply',
      () async {
        const provider = _VaryingFakeProvider();
        final responses = <String>{};
        for (final companion in Companion.values) {
          for (final style in CoachingStyle.values) {
            responses.add(
              await provider.reply(
                input: 'my knee hurts',
                companion: companion,
                style: style,
              ),
            );
          }
        }

        expect(responses, {AiProvider.safetyRedirect});
      },
    );

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

    test(
      'still returns the shared safety redirect for safety-critical input',
      () async {
        const provider = LocalDeterministicAiProvider();

        final response = await provider.reply(
          input: 'my shoulder is injured',
          companion: Companion.atlas,
          style: CoachingStyle.balanced,
        );

        expect(response, AiProvider.safetyRedirect);
      },
    );
  });
}
