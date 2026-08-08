import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/notifications/domain/notification_deep_link.dart';
import 'package:mobile/features/notifications/domain/notification_models.dart';

void main() {
  group('deepLinkPathFor', () {
    for (final type in [
      NotificationEventType.workoutReminder,
      NotificationEventType.restDayReminder,
      NotificationEventType.waterReminder,
      NotificationEventType.mealReminder,
    ]) {
      test('$type has no deep link — the user is already at the inbox', () {
        expect(deepLinkPathFor(type, 'irrelevant'), isNull);
      });
    }

    test('achievementUnlocked always opens the achievements list', () {
      expect(
        deepLinkPathFor(NotificationEventType.achievementUnlocked, null),
        '/achievements',
      );
    });

    test('friendRequest always opens the Friends list', () {
      expect(
        deepLinkPathFor(NotificationEventType.friendRequest, null),
        '/social/friends',
      );
    });

    test(
      'directMessage opens the specific conversation when data is present',
      () {
        expect(
          deepLinkPathFor(NotificationEventType.directMessage, 'conv-1'),
          '/messages/conv-1',
        );
      },
    );

    test('directMessage has no deep link when data is missing', () {
      expect(
        deepLinkPathFor(NotificationEventType.directMessage, null),
        isNull,
      );
    });

    test('groupInvite opens the specific trainer group', () {
      expect(
        deepLinkPathFor(NotificationEventType.groupInvite, 'group-1'),
        '/social/groups/group-1',
      );
    });

    test('challenge opens the specific challenge', () {
      expect(
        deepLinkPathFor(NotificationEventType.challenge, 'challenge-1'),
        '/leaderboards/challenges/challenge-1',
      );
    });

    test('jointWorkout opens the specific joint workout', () {
      expect(
        deepLinkPathFor(NotificationEventType.jointWorkout, 'jw-1'),
        '/social/joint-workouts/jw-1',
      );
    });

    test('sportsMatch opens the specific match', () {
      expect(
        deepLinkPathFor(NotificationEventType.sportsMatch, 'match-1'),
        '/social/sports/match-1',
      );
    });
  });
}
