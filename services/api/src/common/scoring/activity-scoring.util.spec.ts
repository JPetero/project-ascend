import { WorkoutSessionStatus } from '@prisma/client';
import { computeActivitySummary } from './activity-scoring.util';

describe('computeActivitySummary', () => {
  let prisma: {
    workoutSession: { findMany: jest.Mock };
    cardioSession: { findMany: jest.Mock };
    mealEntry: { findMany: jest.Mock };
  };

  beforeEach(() => {
    prisma = {
      workoutSession: { findMany: jest.fn().mockResolvedValue([]) },
      cardioSession: { findMany: jest.fn().mockResolvedValue([]) },
      mealEntry: { findMany: jest.fn().mockResolvedValue([]) },
    };
  });

  const range = () => ({
    from: new Date('2026-08-01T00:00:00Z'),
    to: new Date('2026-08-31T23:59:59Z'),
  });

  it('scores zero with no activity at all', async () => {
    const { from, to } = range();
    const summary = await computeActivitySummary(prisma as never, 'user-1', from, to);

    expect(summary).toEqual({ activeDays: 0, points: 0 });
  });

  it('awards exactly one point for a day with only one domain logged', async () => {
    prisma.workoutSession.findMany.mockResolvedValue([
      { completedAt: new Date('2026-08-05T10:00:00Z') },
    ]);
    const { from, to } = range();

    const summary = await computeActivitySummary(prisma as never, 'user-1', from, to);

    expect(summary).toEqual({ activeDays: 1, points: 1 });
  });

  it('awards the variety bonus (2 points) when two domains land on the same day', async () => {
    prisma.workoutSession.findMany.mockResolvedValue([
      { completedAt: new Date('2026-08-05T10:00:00Z') },
    ]);
    prisma.cardioSession.findMany.mockResolvedValue([
      { startedAt: new Date('2026-08-05T18:00:00Z') },
    ]);
    const { from, to } = range();

    const summary = await computeActivitySummary(prisma as never, 'user-1', from, to);

    expect(summary).toEqual({ activeDays: 1, points: 2 });
  });

  it('caps a day at 2 points even with all three domains logged', async () => {
    prisma.workoutSession.findMany.mockResolvedValue([
      { completedAt: new Date('2026-08-05T08:00:00Z') },
    ]);
    prisma.cardioSession.findMany.mockResolvedValue([
      { startedAt: new Date('2026-08-05T18:00:00Z') },
    ]);
    prisma.mealEntry.findMany.mockResolvedValue([{ date: new Date('2026-08-05T00:00:00Z') }]);
    const { from, to } = range();

    const summary = await computeActivitySummary(prisma as never, 'user-1', from, to);

    expect(summary).toEqual({ activeDays: 1, points: 2 });
  });

  it('never rewards raw volume — ten workouts in one day still count as a single active day', async () => {
    prisma.workoutSession.findMany.mockResolvedValue(
      Array.from({ length: 10 }, () => ({ completedAt: new Date('2026-08-05T08:00:00Z') })),
    );
    const { from, to } = range();

    const summary = await computeActivitySummary(prisma as never, 'user-1', from, to);

    expect(summary).toEqual({ activeDays: 1, points: 1 });
  });

  it('sums points across multiple distinct days', async () => {
    prisma.workoutSession.findMany.mockResolvedValue([
      { completedAt: new Date('2026-08-05T08:00:00Z') },
      { completedAt: new Date('2026-08-06T08:00:00Z') },
    ]);
    const { from, to } = range();

    const summary = await computeActivitySummary(prisma as never, 'user-1', from, to);

    expect(summary).toEqual({ activeDays: 2, points: 2 });
  });

  it('queries workout sessions for COMPLETED status only, within the given range', async () => {
    const { from, to } = range();

    await computeActivitySummary(prisma as never, 'user-1', from, to);

    expect(prisma.workoutSession.findMany).toHaveBeenCalledWith({
      where: {
        userId: 'user-1',
        status: WorkoutSessionStatus.COMPLETED,
        completedAt: { gte: from, lte: to },
      },
      select: { completedAt: true },
    });
  });

  it(
    'never touches Ascend Promote data — a paid impression/click has zero code ' +
      'path into Ranking scoring (Founder Scenario 23)',
    async () => {
      // No `promotedImpression`/`promotedClick`/`promotedCampaign` key
      // exists on this mock at all. If computeActivitySummary ever
      // queried one, this test would fail with a "not a function"
      // TypeError rather than silently passing — the same pattern that
      // caught a genuinely missing mock earlier this session.
      prisma.workoutSession.findMany.mockResolvedValue([
        { completedAt: new Date('2026-08-05T08:00:00Z') },
      ]);
      const { from, to } = range();

      const summary = await computeActivitySummary(prisma as never, 'user-1', from, to);

      expect(summary).toEqual({ activeDays: 1, points: 1 });
    },
  );
});
