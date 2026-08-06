/**
 * A single row in any domain's activity timeline — a completed workout
 * session, a day's nutrition log, eventually a night of sleep or a
 * wearable sync. There is deliberately no shared `History` database
 * table (each domain already has its own natural source of truth —
 * `WorkoutSession`, `MealEntry`, ...; see `workout-history.service.ts`'s
 * own note on why it reads live from `WorkoutSession` instead of a
 * separate table). This interface is the common *shape* a domain's
 * history read-model serializes down to, so a cross-domain timeline can
 * merge entries from several domains without knowing their internals.
 */
export interface HistoryEntry {
  id: string;
  domain: 'workout' | 'nutrition' | 'sleep' | 'wearable';
  occurredAt: Date;
  title: string;
  summary?: string;
}

/** Merges already-fetched entries from one or more domains into a single
 * reverse-chronological timeline. Each domain still owns its own
 * pagination/filtering — this only interleaves already-small result
 * pages (e.g. "today's dashboard activity feed"), not a full history
 * query planner. */
export function mergeHistoryTimelines(...entryLists: HistoryEntry[][]): HistoryEntry[] {
  return entryLists.flat().sort((a, b) => b.occurredAt.getTime() - a.occurredAt.getTime());
}
