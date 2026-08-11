/**
 * S13 Part 8 — a Rankings/leaderboard query filter, not a persisted
 * field (nothing in the schema needs to store which category a row
 * belongs to; a workout/cardio/nutrition entry's domain is already
 * implicit in which table it lives in). OVERALL preserves the
 * pre-existing blended score exactly; the other three isolate one of
 * the domains {@link computeActivitySummary} already tracks separately
 * before blending them.
 */
export enum RankingCategory {
  OVERALL = 'OVERALL',
  STRENGTH = 'STRENGTH',
  CARDIO = 'CARDIO',
  NUTRITION = 'NUTRITION',
}
