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
    if (!subscription || subscription.tier !== 'PREMIUM') return PlanTier.FREE;

    if (subscription.expiresAt && subscription.expiresAt < new Date()) {
      // Build Session 12 Part 22 — purchase reconciliation. There's no
      // cron or store webhook re-verifying subscriptions (that would
      // need real App Store Server Notifications / Google Play RTDN
      // infrastructure this session has nothing to test against); this
      // lazy check is what actually closes the gap instead — every
      // capability check funnels through this one method, so a store
      // subscription whose stated period has lapsed downgrades to FREE
      // (and is persisted, so the DB row stops silently lying) the
      // moment anyone reads it, not just at some future poll interval.
      await this.prisma.userSubscription.update({
        where: { userId },
        data: { tier: 'FREE' },
      });
      return PlanTier.FREE;
    }

    return PlanTier.PREMIUM;
  }

  hasCapability(tier: PlanTier, capability: AppCapability): boolean {
    return resolveHasCapability(tier, capability);
  }

  async hasCapabilityForUser(userId: string, capability: AppCapability): Promise<boolean> {
    return this.hasCapability(await this.getPlanTier(userId), capability);
  }
}
