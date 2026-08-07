import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AppCapability, PlanTier, resolveHasCapability } from './capability.util';

/**
 * Single entry point for every capability check — see
 * packages/docs/product/free-premium-policy.md. `getPlanTier` reads the
 * real per-user `UserSubscription` row (Founder Scenario 27's
 * subscription foundation); no row at all resolves to `PlanTier.FREE`,
 * the same "absence = default" pattern used throughout this schema. No
 * billing/payment integration exists this session, so nothing ever
 * writes a PREMIUM row yet — the point of routing through this service
 * now is that call sites never hardcode `isPremium` logic themselves,
 * only this file needs to change when a payment provider webhook lands.
 */
@Injectable()
export class CapabilityService {
  constructor(private readonly prisma: PrismaService) {}

  async getPlanTier(userId: string): Promise<PlanTier> {
    const subscription = await this.prisma.userSubscription.findUnique({ where: { userId } });
    return subscription?.tier === 'PREMIUM' ? PlanTier.PREMIUM : PlanTier.FREE;
  }

  hasCapability(tier: PlanTier, capability: AppCapability): boolean {
    return resolveHasCapability(tier, capability);
  }

  async hasCapabilityForUser(userId: string, capability: AppCapability): Promise<boolean> {
    return this.hasCapability(await this.getPlanTier(userId), capability);
  }
}
