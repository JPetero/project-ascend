import { Injectable } from '@nestjs/common';
import { AppCapability, PlanTier, resolveHasCapability } from './capability.util';

/**
 * Single entry point for every capability check — see
 * packages/docs/product/free-premium-policy.md. No billing exists yet
 * this session, so every account resolves to PlanTier.FREE; real per-user
 * tier resolution ships alongside subscriptions/payment processing (see
 * packages/docs/product/parking-lot.md). The point of routing through this
 * service now, even with a single hardcoded tier, is that call sites never
 * hardcode `isPremium` logic themselves — only this file needs to change
 * when billing lands.
 */
@Injectable()
export class CapabilityService {
  getPlanTier(_userId: string): PlanTier {
    return PlanTier.FREE;
  }

  hasCapability(tier: PlanTier, capability: AppCapability): boolean {
    return resolveHasCapability(tier, capability);
  }

  hasCapabilityForUser(userId: string, capability: AppCapability): boolean {
    return this.hasCapability(this.getPlanTier(userId), capability);
  }
}
