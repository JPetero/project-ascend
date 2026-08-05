/// A fully local, deterministic response generator for the Ascend Command
/// Center. This intentionally has no external AI dependency yet — it exists
/// so the chat UI is testable and demonstrably functional before a real AI
/// gateway (see packages/docs/roadmap.md) is wired in.
class LocalCompanionResponseService {
  const LocalCompanionResponseService();

  String respond(String input) {
    final normalized = input.trim().toLowerCase();

    if (normalized.isEmpty) {
      return "I didn't catch that — try asking about your workout, a meal, or your progress.";
    }

    if (_containsAny(normalized, const ['workout', 'exercise', 'train'])) {
      return "Let's move. Head to the Workout tab to start today's session, or tell me how much "
          'time you have and I can suggest a focus.';
    }

    if (_containsAny(normalized, const [
      'meal',
      'food',
      'eat',
      'nutrition',
      'protein',
    ])) {
      return 'Logging meals helps me understand your patterns over time. Open the Home tab and use '
          "the log-a-meal quick action, and I'll help you stay on track with your goals.";
    }

    if (_containsAny(normalized, const ['progress', 'streak', 'stats'])) {
      return "You're building momentum. Check your Home dashboard for your current streak, "
          'hydration, and recent activity.';
    }

    if (_containsAny(normalized, const ['sleep', 'rest', 'recovery'])) {
      return 'Recovery is part of training, not a break from it. Aim for consistent sleep and '
          "I'll factor it into your recommendations as wearable data comes online.";
    }

    if (_containsAny(normalized, const ['hurt', 'pain', 'injury', 'injured'])) {
      return "I'm not able to diagnose or treat injuries. If something hurts, please consult a "
          "qualified medical professional — I can help you find lower-impact options in the meantime.";
    }

    if (_containsAny(normalized, const ['hi', 'hello', 'hey'])) {
      return "Hey! I'm here whenever you want to plan a workout, log a meal, or check your progress.";
    }

    return "I'm still learning to answer that fully, but I'm always ready to help with workouts, "
        'meals, and tracking your progress.';
  }

  bool _containsAny(String input, List<String> keywords) {
    return keywords.any(input.contains);
  }
}
