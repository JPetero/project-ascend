import { Test } from '@nestjs/testing';
import { PersonalRecordType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { PersonalRecordsService } from './personal-records.service';

describe('PersonalRecordsService', () => {
  let service: PersonalRecordsService;
  let prisma: {
    workoutSet: { findMany: jest.Mock };
    personalRecord: { findMany: jest.Mock; upsert: jest.Mock };
  };

  beforeEach(async () => {
    prisma = {
      workoutSet: { findMany: jest.fn() },
      personalRecord: { findMany: jest.fn().mockResolvedValue([]), upsert: jest.fn() },
    };

    const moduleRef = await Test.createTestingModule({
      providers: [PersonalRecordsService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = moduleRef.get(PersonalRecordsService);
  });

  function set(overrides: Partial<Record<string, unknown>> = {}) {
    return {
      id: 'set-1',
      workoutSessionId: 'session-1',
      exerciseId: 'exercise-1',
      setNumber: 1,
      reps: null,
      weightKg: null,
      durationSeconds: null,
      distanceMeters: null,
      isWarmup: false,
      completedAt: new Date(),
      ...overrides,
    };
  }

  it('queries only non-warmup sets for the finished session', async () => {
    prisma.workoutSet.findMany.mockResolvedValue([]);

    await service.detectAndRecord('user-1', 'session-1');

    expect(prisma.workoutSet.findMany).toHaveBeenCalledWith({
      where: { workoutSessionId: 'session-1', isWarmup: false },
    });
  });

  it(
    'batches every exercise’s existing records into a single findMany ' +
      'instead of one lookup per candidate (Build Session 10 Parts 27-29)',
    async () => {
      prisma.workoutSet.findMany.mockResolvedValue([
        set({ reps: 8, weightKg: 60 }),
        set({ id: 'set-2', exerciseId: 'exercise-2', reps: 5, weightKg: 40 }),
      ]);
      prisma.personalRecord.upsert.mockImplementation(({ create }) =>
        Promise.resolve({ id: 'pr-1', ...create, exercise: { id: create.exerciseId } }),
      );

      await service.detectAndRecord('user-1', 'session-1');

      expect(prisma.personalRecord.findMany).toHaveBeenCalledTimes(1);
      expect(prisma.personalRecord.findMany).toHaveBeenCalledWith({
        where: { userId: 'user-1', exerciseId: { in: ['exercise-1', 'exercise-2'] } },
      });
    },
  );

  it('records a first-ever personal record when none existed before', async () => {
    prisma.workoutSet.findMany.mockResolvedValue([
      set({ reps: 8, weightKg: 60 }),
      set({ id: 'set-2', setNumber: 2, reps: 8, weightKg: 65 }),
    ]);
    prisma.personalRecord.upsert.mockImplementation(({ create }) =>
      Promise.resolve({ id: 'pr-1', ...create, exercise: { id: 'exercise-1' } }),
    );

    const broken = await service.detectAndRecord('user-1', 'session-1');

    const maxWeight = broken.find((r) => r.type === PersonalRecordType.MAX_WEIGHT);
    expect(maxWeight).toBeDefined();
    expect(maxWeight!.value).toBe(65);
    expect(maxWeight!.isFirstRecord).toBe(true);
    expect(maxWeight!.previousValue).toBeNull();
  });

  it('computes MAX_VOLUME as the sum of reps × weight across the session', async () => {
    prisma.workoutSet.findMany.mockResolvedValue([
      set({ reps: 8, weightKg: 60 }),
      set({ id: 'set-2', setNumber: 2, reps: 8, weightKg: 65 }),
      set({ id: 'set-3', setNumber: 3, reps: 8, weightKg: 67.5 }),
    ]);
    prisma.personalRecord.upsert.mockImplementation(({ create }) =>
      Promise.resolve({ id: 'pr-1', ...create, exercise: { id: 'exercise-1' } }),
    );

    const broken = await service.detectAndRecord('user-1', 'session-1');

    const volume = broken.find((r) => r.type === PersonalRecordType.MAX_VOLUME);
    expect(volume!.value).toBe(8 * 60 + 8 * 65 + 8 * 67.5);
  });

  it('does not overwrite an existing record when the new value does not beat it', async () => {
    // A single set carrying both reps and weight yields four candidates
    // (MAX_WEIGHT, MAX_REPS, MAX_VOLUME, ESTIMATED_ONE_REP_MAX) — every one
    // of them must already have an unbeatable existing record for "nothing
    // breaks" to hold.
    prisma.workoutSet.findMany.mockResolvedValue([set({ reps: 5, weightKg: 50 })]);
    prisma.personalRecord.findMany.mockResolvedValue(
      [
        PersonalRecordType.MAX_WEIGHT,
        PersonalRecordType.MAX_REPS,
        PersonalRecordType.MAX_VOLUME,
        PersonalRecordType.ESTIMATED_ONE_REP_MAX,
      ].map((type) => ({ id: `existing-${type}`, exerciseId: 'exercise-1', type, value: 999_999 })),
    );

    const broken = await service.detectAndRecord('user-1', 'session-1');

    expect(broken).toHaveLength(0);
    expect(prisma.personalRecord.upsert).not.toHaveBeenCalled();
  });

  it('updates a record in place (not append-only) when a new best is set', async () => {
    prisma.workoutSet.findMany.mockResolvedValue([set({ reps: 5, weightKg: 90 })]);
    prisma.personalRecord.findMany.mockResolvedValue([
      { id: 'existing', exerciseId: 'exercise-1', type: PersonalRecordType.MAX_WEIGHT, value: 80 },
    ]);
    // A real Prisma upsert always returns the full row, including fields
    // (userId/exerciseId/type) that live only in `where`/`create`, not in
    // `update` — the mock has to reflect that or `type` comes back
    // `undefined` on the update path.
    prisma.personalRecord.upsert.mockImplementation(({ where, update }) =>
      Promise.resolve({
        id: 'existing',
        ...where.userId_exerciseId_type,
        ...update,
        exercise: { id: 'exercise-1' },
      }),
    );

    const broken = await service.detectAndRecord('user-1', 'session-1');

    const maxWeight = broken.find((r) => r.type === PersonalRecordType.MAX_WEIGHT);
    expect(maxWeight!.value).toBe(90);
    expect(maxWeight!.previousValue).toBe(80);
    expect(maxWeight!.isFirstRecord).toBe(false);
    expect(prisma.personalRecord.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          userId_exerciseId_type: {
            userId: 'user-1',
            exerciseId: 'exercise-1',
            type: PersonalRecordType.MAX_WEIGHT,
          },
        },
      }),
    );
  });

  it('does not compute MAX_VOLUME when no set has both reps and weight', async () => {
    prisma.workoutSet.findMany.mockResolvedValue([set({ durationSeconds: 60 })]);
    prisma.personalRecord.upsert.mockImplementation(({ create }) =>
      Promise.resolve({ id: 'pr-1', ...create, exercise: { id: 'exercise-1' } }),
    );

    const broken = await service.detectAndRecord('user-1', 'session-1');

    expect(broken.some((r) => r.type === PersonalRecordType.MAX_VOLUME)).toBe(false);
    expect(broken.some((r) => r.type === PersonalRecordType.MAX_DURATION)).toBe(true);
  });

  it('computes an estimated one-rep max via the Epley formula, capped to sets of 12 reps or fewer', async () => {
    prisma.workoutSet.findMany.mockResolvedValue([
      set({ reps: 5, weightKg: 100 }),
      // A 20-rep set would otherwise dominate the Epley estimate despite
      // being a much lighter, less reliable data point — excluded.
      set({ id: 'set-2', setNumber: 2, reps: 20, weightKg: 100 }),
    ]);
    prisma.personalRecord.upsert.mockImplementation(({ create }) =>
      Promise.resolve({ id: 'pr-1', ...create, exercise: { id: 'exercise-1' } }),
    );

    const broken = await service.detectAndRecord('user-1', 'session-1');

    const estimated1rm = broken.find((r) => r.type === PersonalRecordType.ESTIMATED_ONE_REP_MAX);
    expect(estimated1rm).toBeDefined();
    // Epley: 100 * (1 + 5/30) = 116.67, from the 5-rep set only.
    expect(estimated1rm!.value).toBeCloseTo(116.7, 1);
    expect(estimated1rm!.unit).toBe('kg');
  });

  it('computes best pace from sets with both distance and duration, ignoring zero-duration sets', async () => {
    prisma.workoutSet.findMany.mockResolvedValue([
      set({ distanceMeters: 1000, durationSeconds: 300 }),
      set({ id: 'set-2', setNumber: 2, distanceMeters: 500, durationSeconds: 0 }),
    ]);
    prisma.personalRecord.upsert.mockImplementation(({ create }) =>
      Promise.resolve({ id: 'pr-1', ...create, exercise: { id: 'exercise-1' } }),
    );

    const broken = await service.detectAndRecord('user-1', 'session-1');

    const pace = broken.find((r) => r.type === PersonalRecordType.BEST_PACE);
    expect(pace).toBeDefined();
    expect(pace!.value).toBeCloseTo(1000 / 300, 2);
    expect(pace!.unit).toBe('m/s');
  });
});
