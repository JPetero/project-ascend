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
    case NotificationEventType.supportReply:
    case NotificationEventType.supportStatusChanged:
      // [data] is the ticket id.
      return data == null ? null : RoutePaths.supportTicketDetailPath(data);
    case NotificationEventType.moderationAppealUpdate:
      // A moderation appeal is filed as a Support ticket
      // (SupportTicketCategory.MODERATION_APPEAL) — [data] is that
      // ticket's id, not a separate appeal-detail route.
      return data == null ? null : RoutePaths.supportTicketDetailPath(data);
    case NotificationEventType.moderationDecision:
      // No per-decision detail screen exists — Support is where the
      // user can see their reports and file an appeal if they disagree.
      return RoutePaths.support;
    case NotificationEventType.promoteReview:
      return data == null ? null : RoutePaths.promoteCampaignDetailPath(data);
    case NotificationEventType.eligibilityVerificationUpdate:
      // Eligibility application status is shown inline on the
      // subscription screen — there's no separate eligibility route.
      return RoutePaths.subscription;
    case NotificationEventType.trainerVerificationUpdate:
      // No trainer-verification UI exists yet (deferred — see
      // build-session-12.md) — nothing to navigate to.
      return null;
    case NotificationEventType.workoutAssigned:
      // [data] is the assignment id, but there's no per-assignment
      // detail route — the to-do list is the most specific place there
      // is to send the user.
      return RoutePaths.myAssignments;
    case NotificationEventType.groupSessionScheduled:
      // [data] is the scheduled session id, not the group id, so it
      // can't build a group-detail deep link — the groups list is the
      // most specific place there is to send the user.
      return RoutePaths.trainerGroups;
    case NotificationEventType.unknown:
      // Deliberately no navigation for a type this client build doesn't
      // recognize — see NotificationEventType.unknown's doc comment.
      return null;
  }
}
