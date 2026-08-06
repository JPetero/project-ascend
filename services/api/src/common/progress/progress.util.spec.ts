import {
  calculateCompletionPercentage,
  calculateConsecutiveActiveWeeks,
  calculateStreak,
  evaluateAchievements,
  groupByMonth,
  groupByWeek,
} from './progress.util';

describe('progress.util', () => {
  describe('calculateStreak', () => {
    it('counts consecutive days ending today', () => {
      const now = new Date('2026-08-06T12:00:00Z');
      const dates = [
        new Date('2026-08-06T09:00:00Z'),
        new Date('2026-08-05T09:00:00Z'),
        new Date('2026-08-04T09:00:00Z'),
      ];
      expect(calculateStreak(dates, now)).toBe(3);
    });

    it('still counts a streak that ended yesterday (before today is logged)', () => {
      const now = new Date('2026-08-06T07:00:00Z');
      const dates = [new Date('2026-08-05T09:00:00Z'), new Date('2026-08-04T09:00:00Z')];
      expect(calculateStreak(dates, now)).toBe(2);
    });

    it('breaks on a gap', () => {
      const now = new Date('2026-08-06T12:00:00Z');
      const dates = [new Date('2026-08-06T09:00:00Z'), new Date('2026-08-03T09:00:00Z')];
      expect(calculateStreak(dates, now)).toBe(1);
    });

    it('returns 0 for no activity', () => {
      expect(calculateStreak([], new Date())).toBe(0);
    });

    it('returns 0 when the most recent activity was more than a day ago', () => {
      const now = new Date('2026-08-06T12:00:00Z');
      const dates = [new Date('2026-08-01T09:00:00Z')];
      expect(calculateStreak(dates, now)).toBe(0);
    });
  });

  describe('calculateConsecutiveActiveWeeks', () => {
    function daysAgo(now: Date, days: number): Date {
      return new Date(now.getTime() - days * 24 * 60 * 60 * 1000);
    }

    it('counts consecutive weeks with at least one activity, ending this week', () => {
      const now = new Date('2026-08-06T12:00:00Z');
      const dates = [daysAgo(now, 0), daysAgo(now, 7), daysAgo(now, 14), daysAgo(now, 21)];
      expect(calculateConsecutiveActiveWeeks(dates, now)).toBe(4);
    });

    it('still counts a streak whose most recent activity was last week', () => {
      const now = new Date('2026-08-06T12:00:00Z');
      const dates = [daysAgo(now, 7), daysAgo(now, 14)];
      expect(calculateConsecutiveActiveWeeks(dates, now)).toBe(2);
    });

    it('breaks on a skipped week', () => {
      const now = new Date('2026-08-06T12:00:00Z');
      const dates = [daysAgo(now, 0), daysAgo(now, 21)];
      expect(calculateConsecutiveActiveWeeks(dates, now)).toBe(1);
    });

    it('returns 0 for no activity', () => {
      expect(calculateConsecutiveActiveWeeks([], new Date())).toBe(0);
    });
  });

  describe('calculateCompletionPercentage', () => {
    it('computes a normal percentage', () => {
      expect(calculateCompletionPercentage(3, 4)).toBe(75);
    });

    it('clamps at 100 even if completed exceeds target', () => {
      expect(calculateCompletionPercentage(10, 4)).toBe(100);
    });

    it('returns 0 for a non-positive target instead of dividing by zero', () => {
      expect(calculateCompletionPercentage(5, 0)).toBe(0);
    });
  });

  describe('groupByWeek', () => {
    it('buckets entries into Sunday-start weeks', () => {
      const entries = [
        { date: new Date('2026-08-04T00:00:00Z') }, // Tuesday
        { date: new Date('2026-08-09T00:00:00Z') }, // Sunday (next week)
      ];
      const grouped = groupByWeek(entries, (e) => e.date);
      expect(grouped).toHaveLength(2);
      expect(grouped[0].entries).toHaveLength(1);
      expect(grouped[1].entries).toHaveLength(1);
    });
  });

  describe('groupByMonth', () => {
    it('buckets entries by calendar month', () => {
      const entries = [
        { date: new Date('2026-08-01T00:00:00Z') },
        { date: new Date('2026-08-31T00:00:00Z') },
        { date: new Date('2026-09-01T00:00:00Z') },
      ];
      const grouped = groupByMonth(entries, (e) => e.date);
      expect(grouped).toHaveLength(2);
      expect(grouped[0].entries).toHaveLength(2);
      expect(grouped[1].entries).toHaveLength(1);
    });
  });

  describe('evaluateAchievements', () => {
    it('returns only rules whose predicate matches the context', () => {
      const rules = [
        {
          id: 'a',
          title: 'A',
          description: '',
          isUnlocked: (ctx: { count: number }) => ctx.count >= 1,
        },
        {
          id: 'b',
          title: 'B',
          description: '',
          isUnlocked: (ctx: { count: number }) => ctx.count >= 100,
        },
      ];
      expect(evaluateAchievements(rules, { count: 5 }).map((r) => r.id)).toEqual(['a']);
    });
  });
});
