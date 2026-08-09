import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AiUsageWindow } from './ai-resilience.types';

const WINDOW_MS = 24 * 60 * 60 * 1000;

// Deliberately generous — this is a fair-use ceiling against runaway/
// scripted abuse, not a per-tier product limit. Premium's own marketing
// promise ("unlimited" conversations) never gets a user-facing credit
// counter; this only ever engages for genuinely abnormal usage.
const DEFAULT_DAILY_LIMIT = 200;

export const FAIR_USE_LIMIT_MESSAGE =
  "You've reached today's Advanced AI conversation limit. It resets within 24 hours — in " +
  'the meantime, your companion can still chat using its standard local responses.';

/**
 * Fair-use ceiling for `AiFeature.ADVANCED_CONVERSATION` (Build Session
 * 12 Part 6) — separate from `AiEntitlementService`, which only answers
 * "does this tier include this feature at all." This answers "has this
 * specific account sent an abnormal volume of live-provider messages
 * today," which a static Premium/Free split can't express. Never gates
 * `AiFeature.ESSENTIAL_SAFETY` — that check never runs for safety-gated
 * replies since they never reach a provider in the first place (see
 * AssistantService.reply).
 *
 * Backed by `AiUsageEvent` rather than an in-memory counter — unlike
 * `AiProviderCircuitBreaker`'s per-process operational state, fair-use
 * counting needs to survive a restart and (eventually) work across
 * multiple instances, so it goes through the database like every other
 * durable count in this codebase.
 */
@Injectable()
export class AiUsagePolicy {
  constructor(private readonly prisma: PrismaService) {}

  async checkWithinLimit(
    userId: string,
    feature: string,
  ): Promise<{ allowed: boolean; window: AiUsageWindow }> {
    const windowStart = new Date(Date.now() - WINDOW_MS);
    const count = await this.prisma.aiUsageEvent.count({
      where: { userId, feature, success: true, createdAt: { gte: windowStart } },
    });
    return {
      allowed: count < DEFAULT_DAILY_LIMIT,
      window: { windowStart, count, limit: DEFAULT_DAILY_LIMIT },
    };
  }

  /**
   * Best-effort — a usage-logging failure must never take down a reply
   * the user already received (or is about to).
   */
  async record(event: {
    userId: string;
    provider: string;
    model?: string;
    feature: string;
    tier: string;
    success: boolean;
    latencyMs: number;
    inputChars: number;
    outputChars?: number;
  }): Promise<void> {
    await this.prisma.aiUsageEvent.create({ data: event }).catch(() => undefined);
  }
}
