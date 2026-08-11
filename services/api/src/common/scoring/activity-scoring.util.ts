import { CardioSessionSource, WorkoutSessionStatus } from '@prisma/client';
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
  /**
   * S13 Part 8 — the per-domain breakdown `points` blends away, kept
   * alongside it so a leaderboard entry is never "an unexplained number
   * that mixes unrelated metrics" (design-bible.md's Rankings
   * requirement that ranking criteria be genuinely transparent, not a
   * black box). Also what a category-filtered leaderboard sorts by:
   * a single-domain view has no cross-domain bonus to apply, so its
   * score is just that domain's active-day count.
   */
  strengthDays: number;
  cardioDays: number;
  nutritionDays: number;
  /**
   * Of `cardioDays`, how many had at least one session recorded via
   * `CardioSessionSource.LIVE_GPS` or `WEARABLE` rather than typed in
   * manually — the provenance half of Part 8. Extends the same
   * distinction `CardioSession.source` already makes (see its own doc
   * comment in schema.prisma) into Rankings instead of inventing a new
   * verification concept; `WorkoutSession`/`MealEntry` have no
   * analogous source field yet, so this signal exists for cardio only.
   */
  verifiedCardioDays: number;
}

function utcDateKey(date: Date): string {
  return date.toISOString().slice(0, 10);
}

function isVerifiedSource(source: CardioSessionSource): boolean {
  return source !== CardioSessionSource.MANUAL;
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
      select: { startedAt: true, source: true },
    }),
    prisma.mealEntry.findMany({
      where: { userId, date: { gte: from, lte: to } },
      select: { date: true },
    }),
  ]);

  const workoutDays = new Set(workoutSessions.map((s) => utcDateKey(s.completedAt as Date)));
  const cardioDays = new Set(cardioSessions.map((s) => utcDateKey(s.startedAt)));
  const nutritionDays = new Set(mealEntries.map((m) => utcDateKey(m.date)));
  const verifiedCardioDays = new Set(
    cardioSessions.filter((s) => isVerifiedSource(s.source)).map((s) => utcDateKey(s.startedAt)),
  );

  const allDays = new Set([...workoutDays, ...cardioDays, ...nutritionDays]);

  let points = 0;
  for (const day of allDays) {
    const domainsLogged =
      Number(workoutDays.has(day)) + Number(cardioDays.has(day)) + Number(nutritionDays.has(day));
    points += domainsLogged >= 2 ? 2 : 1;
  }

  return {
    activeDays: allDays.size,
    points,
    strengthDays: workoutDays.size,
    cardioDays: cardioDays.size,
    nutritionDays: nutritionDays.size,
    verifiedCardioDays: verifiedCardioDays.size,
  };
}

/**
 * Batched sibling of {@link computeActivitySummary} for fan-out call
 * sites that need a summary per candidate in one shot — a leaderboard
 * or a challenge's participant list — instead of one round of 3 queries
 * per candidate (`Promise.all(candidateIds.map(computeActivitySummary))`
 * was the real N+1 pattern this replaced). Candidates absent from the
 * result map had no qualifying activity at all in the window.
 */
export async function computeActivitySummaries(
  prisma: PrismaService,
  userIds: string[],
  from: Date,
  to: Date,
): Promise<Map<string, ActivitySummary>> {
  if (userIds.length === 0) return new Map();

  const [workoutSessions, cardioSessions, mealEntries] = await Promise.all([
    prisma.workoutSession.findMany({
      where: {
        userId: { in: userIds },
        status: WorkoutSessionStatus.COMPLETED,
        completedAt: { gte: from, lte: to },
      },
      select: { userId: true, completedAt: true },
    }),
    prisma.cardioSession.findMany({
      where: { userId: { in: userIds }, startedAt: { gte: from, lte: to } },
      select: { userId: true, startedAt: true, source: true },
    }),
    prisma.mealEntry.findMany({
      where: { userId: { in: userIds }, date: { gte: from, lte: to } },
      select: { userId: true, date: true },
    }),
  ]);

  const workoutDaysByUser = groupDayKeysByUser(workoutSessions, (s) => s.completedAt as Date);
  const cardioDaysByUser = groupDayKeysByUser(cardioSessions, (s) => s.startedAt);
  const nutritionDaysByUser = groupDayKeysByUser(mealEntries, (m) => m.date);
  const verifiedCardioDaysByUser = groupDayKeysByUser(
    cardioSessions.filter((s) => isVerifiedSource(s.source)),
    (s) => s.startedAt,
  );

  const result = new Map<string, ActivitySummary>();
  for (const userId of userIds) {
    const workoutDays = workoutDaysByUser.get(userId) ?? new Set<string>();
    const cardioDays = cardioDaysByUser.get(userId) ?? new Set<string>();
    const nutritionDays = nutritionDaysByUser.get(userId) ?? new Set<string>();
    const verifiedCardioDays = verifiedCardioDaysByUser.get(userId) ?? new Set<string>();
    const allDays = new Set([...workoutDays, ...cardioDays, ...nutritionDays]);

    let points = 0;
    for (const day of allDays) {
      const domainsLogged =
        Number(workoutDays.has(day)) + Number(cardioDays.has(day)) + Number(nutritionDays.has(day));
      points += domainsLogged >= 2 ? 2 : 1;
    }
    result.set(userId, {
      activeDays: allDays.size,
      points,
      strengthDays: workoutDays.size,
      cardioDays: cardioDays.size,
      nutritionDays: nutritionDays.size,
      verifiedCardioDays: verifiedCardioDays.size,
    });
  }
  return result;
}

function groupDayKeysByUser<T extends { userId: string }>(
  rows: T[],
  getDate: (row: T) => Date,
): Map<string, Set<string>> {
  const map = new Map<string, Set<string>>();
  for (const row of rows) {
    const set = map.get(row.userId) ?? new Set<string>();
    set.add(utcDateKey(getDate(row)));
    map.set(row.userId, set);
  }
  return map;
}
