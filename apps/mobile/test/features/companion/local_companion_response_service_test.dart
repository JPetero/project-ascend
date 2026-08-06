import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/companion/data/local_companion_response_service.dart';
import 'package:mobile/features/profile/domain/preferences_model.dart';

void main() {
  group('LocalCompanionResponseService', () {
    const service = LocalCompanionResponseService();

    test('gives the same safety redirect regardless of companion or style', () {
      final responses = <String>{};
      for (final companion in Companion.values) {
        for (final style in CoachingStyle.values) {
          responses.add(
            service.respond(
              'my knee hurts',
              companion: companion,
              style: style,
            ),
          );
        }
      }
      expect(responses, hasLength(1));
      expect(responses.single, contains('qualified medical professional'));
      expect(responses.single, isNot(contains('Atlas')));
      expect(responses.single, isNot(contains('Nova')));
    });

    test('varies workout guidance by coaching style', () {
      final responses = CoachingStyle.values
          .map(
            (style) => service.respond(
              'I want to do a workout',
              companion: Companion.atlas,
              style: style,
            ),
          )
          .toSet();
      expect(responses, hasLength(CoachingStyle.values.length));
    });

    test('names the selected companion in a greeting', () {
      expect(
        service.respond('hello', companion: Companion.nova),
        contains('Nova'),
      );
      expect(
        service.respond('hello', companion: Companion.atlas),
        contains('Atlas'),
      );
    });

    test('handles empty input without a companion name', () {
      expect(
        service.respond(''),
        "I didn't catch that — try asking about your workout, a meal, or your progress.",
      );
    });
  });
}
