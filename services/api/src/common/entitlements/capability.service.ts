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

  /**
   * Batched form of `getPlanTier` for callers resolving many users at
   * once (e.g. TrainerGroupsService.listMyGroups' group owners) — one
   * `findMany` plus one `updateMany` for any lapsed rows, instead of a
   * `findUnique`/`update` pair per user. Same lazy-downgrade semantics
   * as `getPlanTier`: an expired PREMIUM row reads and persists as FREE.
   * Deduplicates `userIds` internally, so callers don't need to.
   */
  async getPlanTiersForUsers(userIds: string[]): Promise<Map<string, PlanTier>> {
    const uniqueIds = Array.from(new Set(userIds));
    const result = new Map<string, PlanTier>(uniqueIds.map((id) => [id, PlanTier.FREE]));
    if (uniqueIds.length === 0) return result;

    const subscriptions = await this.prisma.userSubscription.findMany({
      where: { userId: { in: uniqueIds } },
    });

    const now = new Date();
    const expiredUserIds: string[] = [];
    for (const subscription of subscriptions) {
      if (subscription.tier !== 'PREMIUM') continue;
      if (subscription.expiresAt && subscription.expiresAt < now) {
        expiredUserIds.push(subscription.userId);
        continue;
      }
      result.set(subscription.userId, PlanTier.PREMIUM);
    }

    if (expiredUserIds.length > 0) {
      await this.prisma.userSubscription.updateMany({
        where: { userId: { in: expiredUserIds } },
        data: { tier: 'FREE' },
      });
    }

    return result;
  }

  async hasCapabilityForUsers(
    userIds: string[],
    capability: AppCapability,
  ): Promise<Map<string, boolean>> {
    const tiers = await this.getPlanTiersForUsers(userIds);
    return new Map(
      Array.from(tiers.entries()).map(([userId, tier]) => [
        userId,
        this.hasCapability(tier, capability),
      ]),
    );
  }
}
