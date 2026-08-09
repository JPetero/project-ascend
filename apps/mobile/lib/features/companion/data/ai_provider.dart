import 'package:meta/meta.dart';

import '../../profile/domain/preferences_model.dart';
import '../domain/chat_message.dart';
import '../domain/research_answer.dart';

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
///
/// Safety handling has two tiers, per
/// packages/docs/product/user-scenario-bible.md Scenario 19:
///  - **Red flags** (chest pain, fainting, etc.) always get an immediate,
///    non-negotiable redirect to professional/emergency care.
///  - **General pain/soreness mentions** get a *conversational* flow —
///    ask about severity, onset, and whether there was an acute injury
///    before assuming anything, then either escalate to the same
///    professional-evaluation redirect (if the answer is concerning,
///    persistent, severe, or unclear) or give honest, non-diagnostic
///    general guidance. This is the same concerning-symptoms protocol
///    as the red-flag case — Scenario 19 doesn't introduce a second
///    rule, it specifies how the conversational flow applies it.
abstract class AiProvider {
  const AiProvider();

  // Word-for-word identical across every companion and coaching style
  // — per atlas-nova-bible.md's rule that safety content never varies
  // to sound more "on brand." Used both as the immediate red-flag
  // redirect's "please see someone" companion line and as the outcome
  // of a concerning follow-up answer, since both are the same
  // underlying "this needs a professional" instruction.
  static const safetyRedirect =
      "I'm not able to diagnose or treat injuries. If something hurts, please consult a "
      'qualified medical professional — I can help you find lower-impact options in the meantime.';

  // Stronger and more urgent than [safetyRedirect] — reserved for
  // red-flag symptoms that may need immediate attention, not just a
  // "see a professional eventually" nudge.
  static const emergencyRedirect =
      "That combination of symptoms could be serious. Please seek medical attention right "
      'now — contact a doctor, urgent care, or emergency services. This is not something I '
      'can assess for you.';

  // Public (and @visibleForTesting) so ai_safety_eval_test.dart (Build
  // Session 10 Part 17) can exhaustively exercise the real, live keyword
  // lists and follow-up question below — one source of truth instead of
  // a hand-copied, driftable duplicate in test code.
  @visibleForTesting
  static const painFollowUpQuestion =
      "Before I say anything else — how severe would you say it is, when did it start, and "
      'was there a specific injury (a fall, twist, or impact), or did it come on gradually?';

  static const _generalPainGuidance =
      "Thanks for the detail. That sounds like it could be common muscle soreness or a minor "
      "strain, but I can't diagnose it. Consider resting or modifying your training around it "
      "for a few days — and if it doesn't improve, gets worse, or you're ever unsure, please "
      'check in with a qualified medical professional.';

  // Non-exhaustive, per the bible's own wording.
  @visibleForTesting
  static const emergencyRedFlagKeywords = [
    'chest pain',
    'fainting',
    'fainted',
    'faint',
    'trouble breathing',
    'difficulty breathing',
    "can't breathe",
    'cant breathe',
    'sudden weakness',
    'severe swelling',
    'deformity',
    'deformed',
    "can't bear weight",
    'cant bear weight',
    'unable to bear weight',
    'allergic reaction',
    'anaphylaxis',
    'severe pain',
    'worsening pain',
  ];

  @visibleForTesting
  static const generalPainKeywords = [
    'hurt',
    'pain',
    'injury',
    'injured',
    'sore',
    'soreness',
    'sprain',
    'sprained',
    'strain',
    'strained',
    'ache',
    'aches',
  ];

  // Signals in a follow-up answer that the symptom is concerning,
  // persistent, severe, or unclear — the exact bar the bible sets for
  // recommending professional evaluation rather than general guidance.
  @visibleForTesting
  static const concerningAnswerKeywords = [
    'severe',
    'worse',
    'worsening',
    'weeks',
    'days',
    'still',
    'constant',
    "can't",
    'cant',
    'unable',
    'numb',
    'not sure',
    'unsure',
    "don't know",
    'dont know',
  ];

  Future<String> reply({
    required String input,
    required Companion companion,
    required CoachingStyle style,
    List<ChatMessage> history = const [],
  }) async {
    final normalized = input.trim().toLowerCase();

    if (emergencyRedFlagKeywords.any(normalized.contains)) {
      return emergencyRedirect;
    }

    final awaitingPainFollowUp =
        history.isNotEmpty &&
        !history.last.isFromUser &&
        history.last.text == painFollowUpQuestion;

    if (awaitingPainFollowUp) {
      return concerningAnswerKeywords.any(normalized.contains)
          ? safetyRedirect
          : _generalPainGuidance;
    }

    if (generalPainKeywords.any(normalized.contains)) {
      return painFollowUpQuestion;
    }

    return generateReply(
      input: input,
      companion: companion,
      style: style,
      history: history,
    );
  }

  /// Provider-specific dialogue generation. Never call this directly —
  /// always go through [reply], which enforces the shared safety gate
  /// above before any provider ever sees safety-critical input. [history]
  /// is everything before this turn (same list [reply] received) — a
  /// provider that only produces one-shot replies (like
  /// [LocalDeterministicAiProvider]) can simply ignore it.
  Future<String> generateReply({
    required String input,
    required Companion companion,
    required CoachingStyle style,
    List<ChatMessage> history = const [],
  });

  /// "Research mode" per user-scenario-bible.md Scenario 19: detailed
  /// explanations with citations, evidence-quality labels, and study
  /// dates — sourced only from peer-reviewed research, professional
  /// medical organizations, government health agencies, established
  /// universities, and official clinical guidance. No general web search
  /// result is ever presented as if it were one of those. The system
  /// must admit uncertainty and must never invent a citation.
  ///
  /// This default implementation (still the only one for the local
  /// providers) always reports "not available" — [LiveAiProvider]
  /// overrides this method with a real call to `POST /research/query`
  /// (Build Session 10 Part 16's `BraveSearchResearchProvider`); nothing
  /// else needs to change.
  Future<ResearchAnswer> researchReply({required String query}) async {
    return const ResearchAnswer(
      isAvailable: false,
      unavailableReason:
          "Research mode needs a live, source-verified research provider, which isn't "
          'available yet. Nothing here is invented to fill that gap — for now, please check '
          'a qualified professional or a reputable source directly.',
    );
  }
}
