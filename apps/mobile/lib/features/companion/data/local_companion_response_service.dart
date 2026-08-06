import '../../profile/domain/preferences_model.dart';
import '../domain/companion_dialogue.dart';

/// A fully local, deterministic response generator for the Ascend Command
/// Center. This intentionally has no external AI dependency yet — it exists
/// so the chat UI is testable and demonstrably functional before a real AI
/// gateway (see packages/docs/roadmap.md) is wired in.
///
/// Coaching style varies the voice of every non-safety-critical reply (see
/// packages/docs/product/atlas-nova-bible.md). The injury/pain safety
/// redirect is the one exception: it stays word-for-word identical across
/// every companion and every style, per the bible's rule that safety
/// content never varies to sound more "on brand."
class LocalCompanionResponseService {
  const LocalCompanionResponseService();

  static const _safetyRedirect =
      "I'm not able to diagnose or treat injuries. If something hurts, please consult a "
      'qualified medical professional — I can help you find lower-impact options in the meantime.';

  String respond(
    String input, {
    Companion companion = Companion.atlas,
    CoachingStyle style = CoachingStyle.balanced,
  }) {
    final normalized = input.trim().toLowerCase();
    final name = CompanionDialogue.nameFor(companion);

    if (normalized.isEmpty) {
      return "I didn't catch that — try asking about your workout, a meal, or your progress.";
    }

    if (_containsAny(normalized, const ['hurt', 'pain', 'injury', 'injured'])) {
      return _safetyRedirect;
    }

    if (_containsAny(normalized, const ['workout', 'exercise', 'train'])) {
      return switch (style) {
        CoachingStyle.gentle =>
          "Whenever you're ready, the Workout tab has today's session waiting — no pressure "
              'on timing.',
        CoachingStyle.balanced =>
          "Let's move. Head to the Workout tab to start today's session, or tell me how much "
              'time you have and $name can suggest a focus.',
        CoachingStyle.direct =>
          "Workout tab, today's session. Tell me your available time and I'll narrow the "
              'focus.',
        CoachingStyle.tough =>
          "No excuses — Workout tab, today's session. Tell $name how much time you've got and "
              "let's make it count.",
        CoachingStyle.athlete =>
          "Today's session is in the Workout tab. Give $name your available time and training "
              'focus for an optimized plan.',
      };
    }

    if (_containsAny(normalized, const [
      'meal',
      'food',
      'eat',
      'nutrition',
      'protein',
    ])) {
      return CompanionDialogue.mealSuggestion(
        companion: companion,
        style: style,
      );
    }

    if (_containsAny(normalized, const ['progress', 'streak', 'stats'])) {
      return switch (style) {
        CoachingStyle.gentle =>
          "You're doing this at your own pace, and that's what matters. Check your Home "
              'dashboard for your streak and recent activity whenever you like.',
        CoachingStyle.balanced =>
          "You're building momentum. Check your Home dashboard for your current streak, "
              'hydration, and recent activity.',
        CoachingStyle.direct =>
          'Streak and recent activity are on your Home dashboard.',
        CoachingStyle.tough =>
          "Momentum only holds if you keep showing up. Check your streak on the Home "
              'dashboard — then go add to it.',
        CoachingStyle.athlete =>
          'Your streak, hydration, and recent activity trends are on the Home dashboard — '
              'useful signal for planning your next block.',
      };
    }

    if (_containsAny(normalized, const ['sleep', 'rest', 'recovery'])) {
      return 'Recovery is part of training, not a break from it. Aim for consistent sleep and '
          "$name will factor it into recommendations as wearable data comes online.";
    }

    if (_containsAny(normalized, const [
      'encourag',
      'motivat',
      'tired',
      'don\'t want to',
      'dont want to',
    ])) {
      return switch (style) {
        CoachingStyle.gentle =>
          "It's okay to have an off day. Even a five-minute walk still counts, and $name isn't "
              'going anywhere.',
        CoachingStyle.balanced =>
          '$name is with you. Pick one small thing to do today — a short workout or a logged '
              "meal — and build from there.",
        CoachingStyle.direct =>
          'Pick one action: a workout or a logged meal. Start there.',
        CoachingStyle.tough =>
          "Feelings pass, discipline doesn't. Pick something — a workout, a meal log — and go "
              'do it right now.',
        CoachingStyle.athlete =>
          'Consistency beats intensity. One small session today keeps your training curve on '
              'track — $name suggests starting there.',
      };
    }

    if (_containsAny(normalized, const ['hi', 'hello', 'hey'])) {
      return "Hey! I'm $name, here whenever you want to plan a workout, log a meal, or check "
          'your progress.';
    }

    return "I'm still learning to answer that fully, but $name is always ready to help with "
        'workouts, meals, and tracking your progress.';
  }

  bool _containsAny(String input, List<String> keywords) {
    return keywords.any(input.contains);
  }
}
