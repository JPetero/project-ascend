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

    test('supportReply opens the specific support ticket', () {
      expect(
        deepLinkPathFor(NotificationEventType.supportReply, 'ticket-1'),
        '/support/ticket-1',
      );
    });

    test('supportStatusChanged opens the specific support ticket', () {
      expect(
        deepLinkPathFor(NotificationEventType.supportStatusChanged, 'ticket-1'),
        '/support/ticket-1',
      );
    });

    test(
      'moderationAppealUpdate opens the support ticket the appeal was filed as',
      () {
        expect(
          deepLinkPathFor(
            NotificationEventType.moderationAppealUpdate,
            'ticket-2',
          ),
          '/support/ticket-2',
        );
      },
    );

    test('moderationDecision always opens Support, even with no data', () {
      expect(
        deepLinkPathFor(NotificationEventType.moderationDecision, null),
        '/support',
      );
    });

    test('promoteReview opens the specific campaign', () {
      expect(
        deepLinkPathFor(NotificationEventType.promoteReview, 'campaign-1'),
        '/social/promote/campaign-1',
      );
    });

    test('eligibilityVerificationUpdate opens the subscription screen', () {
      expect(
        deepLinkPathFor(
          NotificationEventType.eligibilityVerificationUpdate,
          null,
        ),
        '/subscription',
      );
    });

    test('trainerVerificationUpdate opens the trainer verification screen', () {
      expect(
        deepLinkPathFor(
          NotificationEventType.trainerVerificationUpdate,
          'anything',
        ),
        '/social/trainer-verification',
      );
    });

    test('an unknown type never navigates, regardless of data', () {
      expect(deepLinkPathFor(NotificationEventType.unknown, 'some-id'), isNull);
    });
  });

  group('notificationEventTypeFromJson fails closed', () {
    test(
      'a type unrecognized by this client build parses to unknown, not directMessage',
      () {
        // Regression for the Build Session 12 Part 1 bug: an unknown
        // server type used to silently fall back to directMessage, which
        // meant a tapped push could open a stranger's conversation
        // thread. SUPPORT_REPLY is used here as a stand-in for "a type
        // added to the backend before this client build knows about
        // it" — the assertion is about the parser's *fallback* behavior
        // for any unrecognized string, not about SUPPORT_REPLY itself
        // (which this build does recognize — see the dedicated test
        // below).
        final type = notificationEventTypeFromJson('FUTURE_TYPE_V99');

        expect(type, NotificationEventType.unknown);
        expect(type, isNot(NotificationEventType.directMessage));
        // And critically: no navigation results from it, even with data
        // that looks like a conversation id.
        expect(deepLinkPathFor(type, 'looks-like-a-conversation-id'), isNull);
      },
    );

    test('tryParseNotificationEventType returns null for an unknown value', () {
      expect(tryParseNotificationEventType('SOMETHING_NEW'), isNull);
    });

    test('SUPPORT_REPLY parses to the real supportReply type', () {
      expect(
        notificationEventTypeFromJson('SUPPORT_REPLY'),
        NotificationEventType.supportReply,
      );
    });
  });
}
