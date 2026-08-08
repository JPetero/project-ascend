import '../../../core/routing/route_paths.dart';
import 'notification_models.dart';

/// Maps a delivered [NotificationEvent] to the in-app route tapping it
/// should open (Build Session 10 Part 13). Returns `null` when there's
/// nothing to navigate to — a reminder just brought the user to the
/// inbox they're already looking at — or when [data] (the entity id the
/// backend attached, e.g. a conversationId) is missing, since a route
/// that takes an id can't be built without one.
String? deepLinkPathFor(NotificationEventType type, String? data) {
  switch (type) {
    case NotificationEventType.workoutReminder:
    case NotificationEventType.restDayReminder:
    case NotificationEventType.waterReminder:
    case NotificationEventType.mealReminder:
      return null;
    case NotificationEventType.achievementUnlocked:
      // No per-achievement detail route exists — the flat list is the
      // most specific place there is to send the user.
      return RoutePaths.achievements;
    case NotificationEventType.friendRequest:
      // No per-request detail route exists — the Friends list is where
      // the pending request itself lives.
      return RoutePaths.friends;
    case NotificationEventType.directMessage:
      return data == null ? null : RoutePaths.conversationDetailPath(data);
    case NotificationEventType.groupInvite:
      return data == null ? null : RoutePaths.trainerGroupDetailPath(data);
    case NotificationEventType.challenge:
      return data == null ? null : RoutePaths.challengeDetailPath(data);
    case NotificationEventType.jointWorkout:
      return data == null ? null : RoutePaths.jointWorkoutDetailPath(data);
    case NotificationEventType.sportsMatch:
      return data == null ? null : RoutePaths.sportMatchDetailPath(data);
  }
}
