import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { WorkoutSessionStatus } from '@prisma/client';
import { calculateConsecutiveActiveWeeks } from '../../common/progress/progress.util';
import { PrismaService } from '../../prisma/prisma.service';

const MIN_CONSECUTIVE_WEEKS = 6;
const HIGH_RPE_THRESHOLD = 8;
const RECENT_WINDOW_DAYS = 14;
// How long a "no recommendation" evaluation is trusted before re-checking —
// keeps this from re-running its query on every single call, and also
// doubles as the anti-nagging window below.
const REEVALUATION_COOLDOWN_DAYS = RECENT_WINDOW_DAYS;

function daysAgo(now: Date, days: number): Date {
  return new Date(now.getTime() - days * 24 * 60 * 60 * 1000);
}

/**
 * Scenario 10 (see packages/docs/product/user-scenario-bible.md): suggests
 * a deload after sustained consistent training combined with recent
 * high-effort sets — never diagnoses overtraining, never auto-applies
 * anything, and never nags (at most one new suggestion per
 * REEVALUATION_COOLDOWN_DAYS, and only while no existing suggestion is
 * still active). Deliberately does not use sleep/recovery signals — no
 * real wearable data source exists yet, and inventing one would violate
 * the "never show fabricated ... values" rule.
 */
@Injectable()
export class DeloadService {
  constructor(private readonly prisma: PrismaService) {}

  /** The user's currently-active recommendation, if any — computing a new
   * one first if none exists and the deterministic signals warrant it. */
  async getActiveRecommendation(userId: string, now: Date = new Date()) {
    const active = await this.prisma.deloadRecommendation.findFirst({
      where: {
        userId,
        dismissedAt: null,
        OR: [{ postponedUntil: null }, { postponedUntil: { lte: now } }],
      },
      orderBy: { suggestedAt: 'desc' },
    });
    if (active) return active;

    return this.evaluateAndMaybeCreate(userId, now);
  }

  private async evaluateAndMaybeCreate(userId: string, now: Date) {
    const recentlyEvaluated = await this.prisma.deloadRecommendation.findFirst({
      where: { userId, suggestedAt: { gte: daysAgo(now, REEVALUATION_COOLDOWN_DAYS) } },
    });
    if (recentlyEvaluated) return null;

    const sessions = await this.prisma.workoutSession.findMany({
      where: { userId, status: WorkoutSessionStatus.COMPLETED, completedAt: { not: null } },
      include: { sets: true },
    });

    const reason = this.computeReason(sessions, now);
    if (!reason) return null;

    return this.prisma.deloadRecommendation.create({ data: { userId, reason } });
  }

  private computeReason(
    sessions: { completedAt: Date | null; sets: { rpe: number | null }[] }[],
    now: Date,
  ): string | null {
    const completedDates = sessions.map((s) => s.completedAt).filter((d): d is Date => d !== null);
    const consecutiveWeeks = calculateConsecutiveActiveWeeks(completedDates, now);
    if (consecutiveWeeks < MIN_CONSECUTIVE_WEEKS) return null;

    const cutoff = daysAgo(now, RECENT_WINDOW_DAYS);
    const recentRpeValues = sessions
      .filter((s) => s.completedAt && s.completedAt >= cutoff)
      .flatMap((s) => s.sets)
      .map((set) => set.rpe)
      .filter((rpe): rpe is number => rpe !== null);

    if (recentRpeValues.length === 0) return null;
    const avgRpe = recentRpeValues.reduce((sum, v) => sum + v, 0) / recentRpeValues.length;
    if (avgRpe < HIGH_RPE_THRESHOLD) return null;

    return (
      `You've trained consistently for ${consecutiveWeeks} weeks in a row, and your recent sets ` +
      `have averaged a high effort rating (RPE ${avgRpe.toFixed(1)}). A short deload — lighter ` +
      `weight or fewer sets for about a week — can help you keep progressing without pushing ` +
      `through accumulated fatigue.`
    );
  }

  async dismiss(userId: string, id: string) {
    return this.updateOwned(userId, id, { dismissedAt: new Date() });
  }

  async postpone(userId: string, id: string, days: number) {
    const postponedUntil = new Date(Date.now() + days * 24 * 60 * 60 * 1000);
    return this.updateOwned(userId, id, { postponedUntil });
  }

  private async updateOwned(userId: string, id: string, data: Record<string, unknown>) {
    const recommendation = await this.prisma.deloadRecommendation.findUnique({ where: { id } });
    if (!recommendation) {
      throw new NotFoundException('That deload recommendation does not exist.');
    }
    if (recommendation.userId !== userId) {
      throw new ForbiddenException();
    }
    return this.prisma.deloadRecommendation.update({ where: { id }, data });
  }
}
