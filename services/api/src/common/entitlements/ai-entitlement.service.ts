import { Injectable } from '@nestjs/common';
import { AppCapability } from './capability.util';
import { CapabilityService } from './capability.service';
import { AiAccessDecision, AiFeature } from './ai-entitlement.types';

/** Never gated by tier — see `AiFeature`'s doc comment. */
const ALWAYS_ALLOWED: ReadonlySet<AiFeature> = new Set([
  AiFeature.ESSENTIAL_SAFETY,
  AiFeature.BASIC_COACHING,
]);

/**
 * free-premium-policy.md doesn't split live-AI conversations, research,
 * voice, long context, or personalization into separate SKUs yet — they
 * all currently resolve to one Premium boundary
 * (`ADVANCED_AI_CONVERSATIONS`, or `PREMIUM_COMPANION_VOICES` for
 * voice). Table form, not a switch, so a future split is a one-line
 * change here instead of a hunt through every controller.
 */
const FEATURE_CAPABILITY: Partial<Record<AiFeature, AppCapability>> = {
  [AiFeature.ADVANCED_CONVERSATION]: AppCapability.ADVANCED_AI_CONVERSATIONS,
  [AiFeature.RESEARCH]: AppCapability.ADVANCED_AI_CONVERSATIONS,
  [AiFeature.VOICE_ADVANCED]: AppCapability.PREMIUM_COMPANION_VOICES,
  [AiFeature.LONG_CONTEXT]: AppCapability.ADVANCED_AI_CONVERSATIONS,
  [AiFeature.PREMIUM_PERSONALIZATION]: AppCapability.ADVANCED_AI_CONVERSATIONS,
};

/**
 * Single authoritative entry point for "is this user allowed to use this
 * AI feature right now" (Build Session 11 Part 1). Before this,
 * `POST /assistant/reply` had no entitlement check at all — any
 * authenticated account, Free or Premium, reached the configured live
 * provider directly, incurring real provider cost with no gate. The
 * mobile client already avoids calling this endpoint for Free accounts
 * (see `LiveAiProvider`'s doc comment), but a client-side-only gate is
 * never trusted server-side — the same principle `ResearchController`
 * already followed for `/research/query`, extended here to be a shared
 * service rather than duplicated per-endpoint logic.
 */
@Injectable()
export class AiEntitlementService {
  constructor(private readonly capabilityService: CapabilityService) {}

  async checkAccess(userId: string, feature: AiFeature): Promise<AiAccessDecision> {
    if (ALWAYS_ALLOWED.has(feature)) {
      return { allowed: true, feature };
    }

    const capability = FEATURE_CAPABILITY[feature];
    if (!capability) {
      // No mapping means this feature was added to the enum but never
      // wired to a capability — fail closed instead of silently
      // allowing an unconfigured gate through.
      return { allowed: false, feature, reason: 'This feature is not yet available.' };
    }

    const allowed = await this.capabilityService.hasCapabilityForUser(userId, capability);
    return { allowed, feature, reason: allowed ? undefined : 'This requires Ascend Premium.' };
  }
}
