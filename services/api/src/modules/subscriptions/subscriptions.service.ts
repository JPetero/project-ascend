import { Injectable } from '@nestjs/common';
import { PRICING_POINTS } from '../../common/config/pricing.config';
import { CapabilityService } from '../../common/entitlements/capability.service';
import { PrismaService } from '../../prisma/prisma.service';
import { ApplyEligibilityDto } from './dto/apply-eligibility.dto';

/**
 * Subscription/entitlement and affordability foundation — Founder
 * Scenario 27. There is deliberately no self-service "upgrade to
 * Premium" endpoint *here* — the real purchase/verification flow lives
 * in PurchasesModule (`POST /purchases/verify`), which is the only
 * thing that ever writes a PREMIUM UserSubscription row, always gated
 * on a real Apple/Google server check (Build Session 9 Part 17/18).
 * This module provides the read side: a real per-user tier read (via
 * CapabilityService), centralized pricing (no literal duplicated
 * anywhere else), and the affordability-program application pipeline,
 * reviewed by admins via AdminModule's eligibility-applications
 * endpoints.
 */
@Injectable()
export class SubscriptionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly capabilityService: CapabilityService,
  ) {}

  getPricing() {
    return PRICING_POINTS;
  }

  async getMyStatus(userId: string) {
    const [tier, eligibility] = await Promise.all([
      this.capabilityService.getPlanTier(userId),
      this.prisma.affordabilityEligibility.findUnique({ where: { userId } }),
    ]);
    return {
      tier,
      eligibility: eligibility
        ? { program: eligibility.program, status: eligibility.status }
        : null,
    };
  }

  async applyForEligibility(userId: string, dto: ApplyEligibilityDto) {
    // Re-applying (e.g. after a REJECTED outcome, or to switch programs)
    // resets the same row back to PENDING rather than erroring on the
    // unique constraint — one live application per user at a time.
    const eligibility = await this.prisma.affordabilityEligibility.upsert({
      where: { userId },
      update: { program: dto.program, notes: dto.notes, status: 'PENDING', reviewedAt: null },
      create: { userId, program: dto.program, notes: dto.notes },
    });
    return { program: eligibility.program, status: eligibility.status };
  }

  async getMyEligibility(userId: string) {
    const eligibility = await this.prisma.affordabilityEligibility.findUnique({
      where: { userId },
    });
    return eligibility ? { program: eligibility.program, status: eligibility.status } : null;
  }
}
