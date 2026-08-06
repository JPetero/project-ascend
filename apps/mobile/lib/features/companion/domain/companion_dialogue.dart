import '../../profile/domain/preferences_model.dart';

/// Deterministic, reviewed dialogue lines for Atlas & Nova — see
/// packages/docs/product/atlas-nova-bible.md. Coaching style drives voice
/// (Gentle/Balanced/Direct/Tough/Athlete); companion drives only the name
/// used in the line. Neither ever changes the underlying facts, and
/// safety-relevant content (see `LocalCompanionResponseService`'s injury
/// redirect) never varies by either — this file only covers the
/// non-safety-critical touchpoints: welcome, missed-workout encouragement,
/// deload framing, celebration, and meal-logging nudges.
class CompanionDialogue {
  const CompanionDialogue._();

  static String nameFor(Companion companion) =>
      companion == Companion.nova ? 'Nova' : 'Atlas';

  static String welcome({
    required Companion companion,
    required CoachingStyle style,
  }) {
    final name = nameFor(companion);
    return switch (style) {
      CoachingStyle.gentle =>
        "Hi, I'm $name. No pressure today — just tell me what would help, "
            "and we'll take it one step at a time.",
      CoachingStyle.balanced =>
        "Hi, I'm $name. Ask me about a workout, a meal, or how your week "
            'is going.',
      CoachingStyle.direct =>
        '$name here. Tell me what you need — workout, meal, or a progress '
            'check.',
      CoachingStyle.tough =>
        "$name here. Let's get to work — what are we tackling today?",
      CoachingStyle.athlete =>
        "$name here. Ready to optimize today's session, fuel, or "
            "recovery — what's the focus?",
    };
  }

  static String missedWorkout({
    required Companion companion,
    required CoachingStyle style,
    required int daysSinceLastWorkout,
  }) {
    final name = nameFor(companion);
    final days = daysSinceLastWorkout == 1
        ? '1 day'
        : '$daysSinceLastWorkout days';
    return switch (style) {
      CoachingStyle.gentle =>
        "It's been $days since your last workout — that's okay, life "
            "happens. Whenever you're ready, $name will be here.",
      CoachingStyle.balanced =>
        "It's been $days since your last workout. $name thinks a short "
            'session today could help you get back into it.',
      CoachingStyle.direct =>
        '$name: $days since your last workout. Ready to get back on '
            'schedule?',
      CoachingStyle.tough =>
        "$name: $days off. That's enough rest — let's get back in and put "
            'in the work.',
      CoachingStyle.athlete =>
        '$name: $days since your last session — training effect starts to '
            "fade. Let's get one in to protect your progress.",
    };
  }

  /// Frames the server-computed [reason] with a tone-appropriate intro —
  /// the reason itself is never rewritten, only introduced, so the factual
  /// content stays identical across every companion and style.
  static String deloadIntro({
    required Companion companion,
    required CoachingStyle style,
  }) {
    final name = nameFor(companion);
    return switch (style) {
      CoachingStyle.gentle =>
        '$name here — I noticed something worth a gentle heads-up:',
      CoachingStyle.balanced => '$name here — a note on your training load:',
      CoachingStyle.direct => '$name: training load flag —',
      CoachingStyle.tough =>
        '$name here — listen up, this matters for your progress:',
      CoachingStyle.athlete =>
        '$name here — a load-management note for peak performance:',
    };
  }

  static String celebration({
    required Companion companion,
    required CoachingStyle style,
    required String achievementTitle,
  }) {
    final name = nameFor(companion);
    return switch (style) {
      CoachingStyle.gentle =>
        '$name is proud of you — you earned "$achievementTitle." Well '
            'done, truly.',
      CoachingStyle.balanced =>
        'Nice work — you earned "$achievementTitle"! $name is cheering you '
            'on.',
      CoachingStyle.direct =>
        '$name: achievement earned — "$achievementTitle." Keep going.',
      CoachingStyle.tough =>
        "$name: that's how it's done. \"$achievementTitle\" — earned, not "
            "given. Don't stop now.",
      CoachingStyle.athlete =>
        '$name: "$achievementTitle" unlocked — solid gains. Keep the trend '
            'line moving.',
    };
  }

  static String mealSuggestion({
    required Companion companion,
    required CoachingStyle style,
  }) {
    final name = nameFor(companion);
    return switch (style) {
      CoachingStyle.gentle =>
        '$name here — whenever it\'s convenient, logging a meal helps '
            'build a clearer picture. No rush.',
      CoachingStyle.balanced =>
        '$name here — logging your meals helps tailor recommendations to '
            'how you\'re actually eating.',
      CoachingStyle.direct =>
        '$name: log today\'s meals for accurate tracking.',
      CoachingStyle.tough =>
        "$name: nutrition is half the work. Log it — don't skip this "
            'part.',
      CoachingStyle.athlete =>
        '$name: precise fueling data improves recommendation accuracy — '
            'log your meals when you can.',
    };
  }

  /// Shown when the outbox has queued, unsynced work (see
  /// `core/sync/sync_status.dart`'s `SyncStatus.pendingCount`). Never
  /// implies data was lost — the outbox itself is the honest record of
  /// what's still queued, this is just companion-voiced framing of it.
  static String offline({
    required Companion companion,
    required CoachingStyle style,
  }) {
    final name = nameFor(companion);
    return switch (style) {
      CoachingStyle.gentle =>
        "$name can't reach the server right now, but anything you log "
            "will sync once you're back online — no rush.",
      CoachingStyle.balanced =>
        "$name is offline right now. What you log will sync automatically "
            'once your connection returns.',
      CoachingStyle.direct =>
        '$name: offline. Logged data syncs automatically once reconnected.',
      CoachingStyle.tough =>
        "$name: connection's down, but that's no excuse to stop. Keep "
            "logging — it'll sync.",
      CoachingStyle.athlete =>
        '$name: offline — data queues locally and syncs the moment '
            'connectivity is restored.',
    };
  }
}
