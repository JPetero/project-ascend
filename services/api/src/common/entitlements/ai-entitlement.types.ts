/**
 * AI-specific feature gates (Build Session 11 Part 1). Distinct from
 * `AppCapability` (`common/entitlements/`) — this enum is the vocabulary
 * the assistant/research pipeline reasons in ("is this turn allowed to
 * reach a live provider"), while `AppCapability` is the product-wide
 * free/premium capability list `AiEntitlementService` ultimately checks
 * against. Keeping them separate means a future split (e.g. voice
 * getting its own SKU) only touches the mapping table in
 * `ai-entitlement.service.ts`, not every call site.
 */
export enum AiFeature {
  /** Never gated — the concerning-symptoms stop-and-redirect content
   * every tier must always get, per wellness-ethics-bible.md. */
  ESSENTIAL_SAFETY = 'ESSENTIAL_SAFETY',
  /** The free, deterministic companion dialogue baseline. */
  BASIC_COACHING = 'BASIC_COACHING',
  ADVANCED_CONVERSATION = 'ADVANCED_CONVERSATION',
  RESEARCH = 'RESEARCH',
  VOICE_ADVANCED = 'VOICE_ADVANCED',
  LONG_CONTEXT = 'LONG_CONTEXT',
  PREMIUM_PERSONALIZATION = 'PREMIUM_PERSONALIZATION',
}

export interface AiAccessDecision {
  allowed: boolean;
  feature: AiFeature;
  /** Present whenever `allowed` is false — safe to surface to the user. */
  reason?: string;
}
