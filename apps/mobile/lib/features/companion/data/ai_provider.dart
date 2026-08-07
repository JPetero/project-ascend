import '../../profile/domain/preferences_model.dart';

/// Provider-independent Ascend AI foundation. See
/// packages/docs/product/atlas-nova-bible.md's "Future: live AI"
/// section: whichever model answers for Atlas or Nova, safety-relevant
/// content must be identical regardless of companion or coaching style
/// — "a shared system-prompt safety layer, not a per-companion one."
/// [reply] is the one entry point every caller uses; it enforces that
/// shared safety gate structurally, extending (not implementing) this
/// class the way [companion] and other abstract classes in this
/// codebase do for a concrete default method — so a future live
/// provider, which only ever overrides [generateReply], can never
/// accidentally bypass the gate. No live provider exists this session
/// (see packages/docs/product/parking-lot.md's "Live AI provider
/// integration" entry); [LocalDeterministicAiProvider] is the only
/// implementation.
abstract class AiProvider {
  const AiProvider();

  // Word-for-word identical across every companion and coaching style
  // — per atlas-nova-bible.md's rule that safety content never varies
  // to sound more "on brand."
  static const safetyRedirect =
      "I'm not able to diagnose or treat injuries. If something hurts, please consult a "
      'qualified medical professional — I can help you find lower-impact options in the meantime.';

  static const _safetyKeywords = ['hurt', 'pain', 'injury', 'injured'];

  Future<String> reply({
    required String input,
    required Companion companion,
    required CoachingStyle style,
  }) async {
    final normalized = input.trim().toLowerCase();
    if (_safetyKeywords.any(normalized.contains)) {
      return safetyRedirect;
    }
    return generateReply(input: input, companion: companion, style: style);
  }

  /// Provider-specific dialogue generation. Never call this directly —
  /// always go through [reply], which enforces the shared safety gate
  /// above before any provider ever sees safety-critical input.
  Future<String> generateReply({
    required String input,
    required Companion companion,
    required CoachingStyle style,
  });
}
