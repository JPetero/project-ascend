/**
 * Build Session 12 Part 6 — AI provider resilience. Plain,
 * decorator-free types shared by `AiProviderCircuitBreaker`,
 * `AiUsagePolicy`, and `AiReplyProviderRouter`.
 */

/** Circuit-breaker state for one provider key ('anthropic'/'openai'/'gemini'). */
export interface ProviderHealth {
  consecutiveFailures: number;
  /** Non-null while the circuit is open (provider treated as unhealthy). */
  openUntil: Date | null;
}

/** One provider attempt during a single `AiReplyProviderRouter.generateReply` call. */
export interface AiProviderAttempt {
  provider: string;
  model?: string;
  success: boolean;
  latencyMs: number;
}

/** A rolling fair-use window snapshot — see `AiUsagePolicy`. */
export interface AiUsageWindow {
  windowStart: Date;
  count: number;
  limit: number;
}
