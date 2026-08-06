import { HistoryEntry, mergeHistoryTimelines } from './history-entry.interface';

function entry(domain: HistoryEntry['domain'], id: string, occurredAt: string): HistoryEntry {
  return { id, domain, occurredAt: new Date(occurredAt), title: id };
}

describe('mergeHistoryTimelines', () => {
  it('interleaves multiple domains into one reverse-chronological list', () => {
    const workoutEntries = [
      entry('workout', 'w1', '2026-08-01T08:00:00Z'),
      entry('workout', 'w2', '2026-08-03T08:00:00Z'),
    ];
    const nutritionEntries = [entry('nutrition', 'n1', '2026-08-02T08:00:00Z')];

    const merged = mergeHistoryTimelines(workoutEntries, nutritionEntries);

    expect(merged.map((e) => e.id)).toEqual(['w2', 'n1', 'w1']);
  });

  it('returns an empty array when given no entries', () => {
    expect(mergeHistoryTimelines([], [])).toEqual([]);
  });
});
