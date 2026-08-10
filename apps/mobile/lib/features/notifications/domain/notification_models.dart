/// Per-category reminder/notification preferences — Build Session 8
/// Part 12. Distinct from the pre-existing global
/// `PreferencesModel.notificationsEnabled` kill switch: that one turns
/// everything off at once, these six turn off one category at a time.
class NotificationPreferences {
  const NotificationPreferences({
    required this.workoutReminders,
    required this.restDayReminders,
    required this.waterReminders,
    required this.mealReminders,
    required this.achievementNotifications,
    required this.socialNotifications,
  });

  final bool workoutReminders;
  final bool restDayReminders;
  final bool waterReminders;
  final bool mealReminders;
  final bool achievementNotifications;
  final bool socialNotifications;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      workoutReminders: json['workoutReminders'] as bool? ?? true,
      restDayReminders: json['restDayReminders'] as bool? ?? true,
      waterReminders: json['waterReminders'] as bool? ?? true,
      mealReminders: json['mealReminders'] as bool? ?? true,
      achievementNotifications:
          json['achievementNotifications'] as bool? ?? true,
      socialNotifications: json['socialNotifications'] as bool? ?? true,
    );
  }

  NotificationPreferences copyWith({
    bool? workoutReminders,
    bool? restDayReminders,
    bool? waterReminders,
    bool? mealReminders,
    bool? achievementNotifications,
    bool? socialNotifications,
  }) {
    return NotificationPreferences(
      workoutReminders: workoutReminders ?? this.workoutReminders,
      restDayReminders: restDayReminders ?? this.restDayReminders,
      waterReminders: waterReminders ?? this.waterReminders,
      mealReminders: mealReminders ?? this.mealReminders,
      achievementNotifications:
          achievementNotifications ?? this.achievementNotifications,
      socialNotifications: socialNotifications ?? this.socialNotifications,
    );
  }
}

enum NotificationEventType {
  workoutReminder,
  restDayReminder,
  waterReminder,
  mealReminder,
  achievementUnlocked,
  friendRequest,
  directMessage,
  groupInvite,
  challenge,
  jointWorkout,
  sportsMatch,
  supportReply,
  supportStatusChanged,
  moderationDecision,
  moderationAppealUpdate,
  promoteReview,
  trainerVerificationUpdate,
  eligibilityVerificationUpdate,
  // Build Session 12 Part 9/10 — a trainer assigning a workout, or
  // scheduling a session for the group.
  workoutAssigned,
  groupSessionScheduled,
  // Build Session 13 Part 3 — the host canceled a booking members had
  // RSVP'd to or were counting on.
  groupSessionCanceled,

  /// A server-sent type this build of the client doesn't recognize yet
  /// (Build Session 12 Part 1) — e.g. an older app version receiving a
  /// category added in a later release. Deliberately fails closed: an
  /// unknown type must never be silently reinterpreted as an existing
  /// category (it used to default to [directMessage], which meant an
  /// unrecognized push could open a stranger's conversation thread).
  /// Renders generically and never drives navigation — see
  /// `deepLinkPathFor`.
  unknown,
}

/// Parses a server `NotificationType` string, failing closed to
/// [NotificationEventType.unknown] for anything this client build
/// doesn't recognize — see [NotificationEventType.unknown]'s doc
/// comment for why silently guessing an existing category is unsafe.
NotificationEventType notificationEventTypeFromJson(String value) {
  return tryParseNotificationEventType(value) ?? NotificationEventType.unknown;
}

/// Same parse as [notificationEventTypeFromJson], but returns `null`
/// instead of [NotificationEventType.unknown] for an unrecognized value
/// — for callers that want to distinguish "recognized as unknown" from
/// "didn't even attempt to parse."
NotificationEventType? tryParseNotificationEventType(String value) {
  switch (value) {
    case 'WORKOUT_REMINDER':
      return NotificationEventType.workoutReminder;
    case 'REST_DAY_REMINDER':
      return NotificationEventType.restDayReminder;
    case 'WATER_REMINDER':
      return NotificationEventType.waterReminder;
    case 'MEAL_REMINDER':
      return NotificationEventType.mealReminder;
    case 'ACHIEVEMENT_UNLOCKED':
      return NotificationEventType.achievementUnlocked;
    case 'FRIEND_REQUEST':
      return NotificationEventType.friendRequest;
    case 'DIRECT_MESSAGE':
      return NotificationEventType.directMessage;
    case 'GROUP_INVITE':
      return NotificationEventType.groupInvite;
    case 'CHALLENGE':
      return NotificationEventType.challenge;
    case 'JOINT_WORKOUT':
      return NotificationEventType.jointWorkout;
    case 'SPORTS_MATCH':
      return NotificationEventType.sportsMatch;
    case 'SUPPORT_REPLY':
      return NotificationEventType.supportReply;
    case 'SUPPORT_STATUS_CHANGED':
      return NotificationEventType.supportStatusChanged;
    case 'MODERATION_DECISION':
      return NotificationEventType.moderationDecision;
    case 'MODERATION_APPEAL_UPDATE':
      return NotificationEventType.moderationAppealUpdate;
    case 'PROMOTE_REVIEW':
      return NotificationEventType.promoteReview;
    case 'TRAINER_VERIFICATION_UPDATE':
      return NotificationEventType.trainerVerificationUpdate;
    case 'ELIGIBILITY_VERIFICATION_UPDATE':
      return NotificationEventType.eligibilityVerificationUpdate;
    case 'WORKOUT_ASSIGNED':
      return NotificationEventType.workoutAssigned;
    case 'GROUP_SESSION_SCHEDULED':
      return NotificationEventType.groupSessionScheduled;
    case 'GROUP_SESSION_CANCELED':
      return NotificationEventType.groupSessionCanceled;
    default:
      return null;
  }
}

/// A single delivered-or-not notification event in the caller's inbox —
/// Build Session 8 Part 12. [data] is free-form deep-link context (e.g.
/// a conversation id), never a health metric.
class NotificationEvent {
  const NotificationEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.data,
    this.readAt,
  });

  final String id;
  final NotificationEventType type;
  final String title;
  final String body;
  final String? data;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  factory NotificationEvent.fromJson(Map<String, dynamic> json) {
    return NotificationEvent(
      id: json['id'] as String,
      type: notificationEventTypeFromJson(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
    );
  }
}
