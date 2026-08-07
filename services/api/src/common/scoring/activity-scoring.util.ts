import { WorkoutSessionStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

export interface ActivitySummary {
  /** Number of distinct calendar days (UTC) with at least one qualifying activity. */
  activeDays: number;
  /**
   * Deliberately not a raw-volume metric (never weight lifted, calories
   * burned, or duration) and never an uninterrupted-streak-only score —
   * see packages/docs/product/user-scenario-bible.md Scenario 16a's
   * "reward consistency and varied healthy behavior, never raw danger"
   * requirement. One point per active day, plus one bonus point for
   * logging in at least two different domains (workout/cardio/nutrition)
   * that same day — capped at 2 points/day so no single domain, however
   * large, can dominate the score.
   */
  points: number;
}

function utcDateKey(date: Date): string {
  return date.toISOString().slice(0, 10);
}

/**
 * Shared by RankingsService (season-window scoring) and ChallengesService
 * (challenge-window progress) — both measure "did this user show up and
 * vary their activity," never how much they did in any one session.
 */
export async function computeActivitySummary(
  prisma: PrismaService,
  userId: string,
  from: Date,
  to: Date,
): Promise<ActivitySummary> {
  const [workoutSessions, cardioSessions, mealEntries] = await Promise.all([
    prisma.workoutSession.findMany({
      where: {
        userId,
        status: WorkoutSessionStatus.COMPLETED,
        completedAt: { gte: from, lte: to },
      },
      select: { completedAt: true },
    }),
    prisma.cardioSession.findMany({
      where: { userId, startedAt: { gte: from, lte: to } },
      select: { startedAt: true },
    }),
    prisma.mealEntry.findMany({
      where: { userId, date: { gte: from, lte: to } },
      select: { date: true },
    }),
  ]);

  const workoutDays = new Set(workoutSessions.map((s) => utcDateKey(s.completedAt as Date)));
  const cardioDays = new Set(cardioSessions.map((s) => utcDateKey(s.startedAt)));
  const nutritionDays = new Set(mealEntries.map((m) => utcDateKey(m.date)));

  const allDays = new Set([...workoutDays, ...cardioDays, ...nutritionDays]);

  let points = 0;
  for (const day of allDays) {
    const domainsLogged =
      Number(workoutDays.has(day)) + Number(cardioDays.has(day)) + Number(nutritionDays.has(day));
    points += domainsLogged >= 2 ? 2 : 1;
  }

  return { activeDays: allDays.size, points };
}
