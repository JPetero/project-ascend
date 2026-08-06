import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/companion/domain/companion_dialogue.dart';
import 'package:mobile/features/profile/domain/preferences_model.dart';

void main() {
  group('CompanionDialogue', () {
    test('welcome names the chosen companion for every style', () {
      for (final style in CoachingStyle.values) {
        expect(
          CompanionDialogue.welcome(companion: Companion.atlas, style: style),
          contains('Atlas'),
        );
        expect(
          CompanionDialogue.welcome(companion: Companion.nova, style: style),
          contains('Nova'),
        );
      }
    });

    test('missedWorkout pluralizes days correctly', () {
      final oneDay = CompanionDialogue.missedWorkout(
        companion: Companion.atlas,
        style: CoachingStyle.balanced,
        daysSinceLastWorkout: 1,
      );
      expect(oneDay, contains('1 day'));
      expect(oneDay, isNot(contains('1 days')));

      final threeDays = CompanionDialogue.missedWorkout(
        companion: Companion.atlas,
        style: CoachingStyle.balanced,
        daysSinceLastWorkout: 3,
      );
      expect(threeDays, contains('3 days'));
    });

    test('deloadIntro frames without rewriting the underlying reason', () {
      final intro = CompanionDialogue.deloadIntro(
        companion: Companion.nova,
        style: CoachingStyle.gentle,
      );
      expect(intro, contains('Nova'));
      expect(intro, isNot(contains('trained')));
    });

    test('celebration includes the exact earned achievement title', () {
      final message = CompanionDialogue.celebration(
        companion: Companion.atlas,
        style: CoachingStyle.tough,
        achievementTitle: 'First Workout Complete',
      );
      expect(message, contains('First Workout Complete'));
    });

    test('every coaching style produces distinct copy', () {
      final messages = CoachingStyle.values
          .map(
            (style) => CompanionDialogue.welcome(
              companion: Companion.atlas,
              style: style,
            ),
          )
          .toSet();
      expect(messages, hasLength(CoachingStyle.values.length));
    });
  });
}
