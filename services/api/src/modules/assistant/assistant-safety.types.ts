/**
 * Server-side safety classification for `/assistant/reply` (Build
 * Session 11 Parts 1-2). Before this, the *only* safety gate was
 * `AiProvider.reply()` on the Flutter client (see
 * `apps/mobile/lib/features/companion/data/ai_provider.dart`) — a direct
 * HTTP call to this endpoint bypassed it entirely. The backend is now
 * authoritative: the client-side gate still runs first for normal in-app
 * use (defense in depth, and it saves a round trip for the common case),
 * but nothing here trusts that it ran.
 */
export enum AssistantSafetyCategory {
  GENERAL = 'GENERAL',
  FITNESS = 'FITNESS',
  NUTRITION = 'NUTRITION',
  RECOVERY = 'RECOVERY',
  PAIN_OR_INJURY = 'PAIN_OR_INJURY',
  MEDICAL_RED_FLAG = 'MEDICAL_RED_FLAG',
  EATING_DISORDER_RISK = 'EATING_DISORDER_RISK',
  EXTREME_DIETING = 'EXTREME_DIETING',
  OVERTRAINING = 'OVERTRAINING',
  DEHYDRATION = 'DEHYDRATION',
  SELF_HARM = 'SELF_HARM',
  ABUSE_OR_CRISIS = 'ABUSE_OR_CRISIS',
  SEXUAL_CONTENT = 'SEXUAL_CONTENT',
  MINOR_SAFETY = 'MINOR_SAFETY',
  DEPENDENCY_LANGUAGE = 'DEPENDENCY_LANGUAGE',
  PERFORMANCE_ENHANCING_DRUGS = 'PERFORMANCE_ENHANCING_DRUGS',
  UNSUPPORTED_PROFESSIONAL_ADVICE = 'UNSUPPORTED_PROFESSIONAL_ADVICE',
  OUT_OF_SCOPE = 'OUT_OF_SCOPE',
}

export enum AssistantSafetyDecisionType {
  /** No safety concern found — proceed to the live provider normally. */
  ALLOW_PROVIDER = 'ALLOW_PROVIDER',
  /** Proceed to the live provider, but with extra situational framing
   * appended to the system prompt for this one turn. */
  ALLOW_WITH_SAFETY_CONTEXT = 'ALLOW_WITH_SAFETY_CONTEXT',
  /** Answer directly with `localResponse` — never reaches a provider.
   * Used for content a deterministic, reviewed reply already handles
   * safely and correctly (no reason to risk a live model improvising on
   * it, and no reason to spend provider budget on it either). */
  LOCAL_SAFE_RESPONSE = 'LOCAL_SAFE_RESPONSE',
  /** Same as LOCAL_SAFE_RESPONSE but for red-flag/crisis content where
   * the reply must point toward immediate professional/emergency help. */
  ESCALATE = 'ESCALATE',
  /** Same as LOCAL_SAFE_RESPONSE but for content Ascend will never
   * engage with regardless of framing (sexual content, minor safety). */
  REFUSE = 'REFUSE',
}

export interface AssistantSafetyDecision {
  category: AssistantSafetyCategory;
  decision: AssistantSafetyDecisionType;
  /** Set whenever `decision` is not ALLOW_PROVIDER/ALLOW_WITH_SAFETY_CONTEXT
   * — the literal reply to return. Never sent to any provider. */
  localResponse?: string;
  /** Set only for ALLOW_WITH_SAFETY_CONTEXT — appended to the system
   * prompt as situational framing for this turn. Never replaces the
   * base safety rules `buildSystemPrompt` always includes. */
  safetyContext?: string;
}
