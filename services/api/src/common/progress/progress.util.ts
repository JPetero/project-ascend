/**
 * Generic progress calculations shared across domains — a workout streak
 * and a "meals logged" streak are the same computation over a different
 * list of dates. Everything here takes plain `Date[]`/numbers in and
 * returns plain values out; no Prisma, no domain knowledge.
 */

function toDayKey(date: Date): string {
  return date.toISOString().slice(0, 10);
}

/**
 * Counts consecutive calendar days (ending today or yesterday — a streak
 * "survives" until a full day is missed) with at least one activity.
 * `activityDates` need not be sorted or deduplicated.
 */
export function calculateStreak(activityDates: Date[], now: Date = new Date()): number {
  const uniqueDays = new Set(activityDates.map(toDayKey));
  if (uniqueDays.size === 0) return 0;

  const cursor = new Date(now);
  cursor.setUTCHours(0, 0, 0, 0);

  // A streak still "counts" if today has no activity yet but yesterday
  // does — otherwise checking first thing in the morning would always
  // show a broken streak.
  if (!uniqueDays.has(toDayKey(cursor))) {
    cursor.setUTCDate(cursor.getUTCDate() - 1);
    if (!uniqueDays.has(toDayKey(cursor))) return 0;
  }

  let streak = 0;
  while (uniqueDays.has(toDayKey(cursor))) {
    streak += 1;
    cursor.setUTCDate(cursor.getUTCDate() - 1);
  }
  return streak;
}

function toWeekKey(date: Date): string {
  const weekStart = new Date(date);
  weekStart.setUTCHours(0, 0, 0, 0);
  weekStart.setUTCDate(weekStart.getUTCDate() - weekStart.getUTCDay());
  return toDayKey(weekStart);
}

/**
 * Counts consecutive calendar weeks (Sunday-start UTC, ending this week or
 * last week — same "still alive until a full week is missed" rule as
 * {@link calculateStreak}) with at least one activity. Used by the deload
 * recommendation service to read "how many weeks in a row has this person
 * trained" off real `WorkoutSession.completedAt` values.
 */
export function calculateConsecutiveActiveWeeks(
  activityDates: Date[],
  now: Date = new Date(),
): number {
  const uniqueWeeks = new Set(activityDates.map(toWeekKey));
  if (uniqueWeeks.size === 0) return 0;

  const cursor = new Date(now);
  cursor.setUTCHours(0, 0, 0, 0);
  cursor.setUTCDate(cursor.getUTCDate() - cursor.getUTCDay());

  if (!uniqueWeeks.has(toDayKey(cursor))) {
    cursor.setUTCDate(cursor.getUTCDate() - 7);
    if (!uniqueWeeks.has(toDayKey(cursor))) return 0;
  }

  let weeks = 0;
  while (uniqueWeeks.has(toDayKey(cursor))) {
    weeks += 1;
    cursor.setUTCDate(cursor.getUTCDate() - 7);
  }
  return weeks;
}

/** Rounded to one decimal place, clamped to [0, 100] — never returns a
 * value that would render a progress ring past full or negative even if
 * `completed` exceeds `target`. */
export function calculateCompletionPercentage(completed: number, target: number): number {
  if (target <= 0) return 0;
  const percentage = (completed / target) * 100;
  return Math.max(0, Math.min(100, Math.round(percentage * 10) / 10));
}

export interface PeriodSummary<T> {
  periodStart: string;
  periodEnd: string;
  entries: T[];
}

/** Buckets entries into 7-day (Sunday-start, UTC) windows using
 * `dateSelector` to read each entry's date. Used for "weekly summary"
 * views — the Nutrition 7-day summary already does its own simpler
 * fixed-window version of this; this is the general form for anything
 * spanning multiple weeks. */
export function groupByWeek<T>(entries: T[], dateSelector: (entry: T) => Date): PeriodSummary<T>[] {
  const buckets = new Map<string, T[]>();
  for (const entry of entries) {
    const date = dateSelector(entry);
    const weekStart = new Date(date);
    weekStart.setUTCHours(0, 0, 0, 0);
    weekStart.setUTCDate(weekStart.getUTCDate() - weekStart.getUTCDay());
    const key = toDayKey(weekStart);
    const bucket = buckets.get(key);
    if (bucket) {
      bucket.push(entry);
    } else {
      buckets.set(key, [entry]);
    }
  }

  return Array.from(buckets.entries())
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([weekStart, bucketEntries]) => {
      const end = new Date(weekStart);
      end.setUTCDate(end.getUTCDate() + 6);
      return { periodStart: weekStart, periodEnd: toDayKey(end), entries: bucketEntries };
    });
}

/** Buckets entries into calendar months (UTC). */
export function groupByMonth<T>(
  entries: T[],
  dateSelector: (entry: T) => Date,
): PeriodSummary<T>[] {
  const buckets = new Map<string, T[]>();
  for (const entry of entries) {
    const date = dateSelector(entry);
    const key = `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, '0')}`;
    const bucket = buckets.get(key);
    if (bucket) {
      bucket.push(entry);
    } else {
      buckets.set(key, [entry]);
    }
  }

  return Array.from(buckets.entries())
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([month, bucketEntries]) => {
      const [year, monthIndex] = month.split('-').map(Number);
      const start = new Date(Date.UTC(year, monthIndex - 1, 1));
      const end = new Date(Date.UTC(year, monthIndex, 0));
      return {
        periodStart: toDayKey(start),
        periodEnd: toDayKey(end),
        entries: bucketEntries,
      };
    });
}

/** An achievement is a rule evaluated over some domain-supplied context —
 * kept intentionally generic (no fixed achievement catalog exists yet in
 * any domain) so Workout and, later, Nutrition can define their own
 * achievement rules against this same shape rather than each building a
 * bespoke achievements system. */
export interface AchievementRule<TContext> {
  id: string;
  title: string;
  description: string;
  isUnlocked: (context: TContext) => boolean;
}

export function evaluateAchievements<TContext>(
  rules: AchievementRule<TContext>[],
  context: TContext,
): AchievementRule<TContext>[] {
  return rules.filter((rule) => rule.isUnlocked(context));
}
