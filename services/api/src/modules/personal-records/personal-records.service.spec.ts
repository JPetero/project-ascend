import { Test } from '@nestjs/testing';
import { PersonalRecordType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { PersonalRecordsService } from './personal-records.service';

describe('PersonalRecordsService', () => {
  let service: PersonalRecordsService;
  let prisma: {
    workoutSet: { findMany: jest.Mock };
    personalRecord: { findUnique: jest.Mock; upsert: jest.Mock };
  };

  beforeEach(async () => {
    prisma = {
      workoutSet: { findMany: jest.fn() },
      personalRecord: { findUnique: jest.fn(), upsert: jest.fn() },
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

  it('records a first-ever personal record when none existed before', async () => {
    prisma.workoutSet.findMany.mockResolvedValue([
      set({ reps: 8, weightKg: 60 }),
      set({ id: 'set-2', setNumber: 2, reps: 8, weightKg: 65 }),
    ]);
    prisma.personalRecord.findUnique.mockResolvedValue(null);
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
    prisma.personalRecord.findUnique.mockResolvedValue(null);
    prisma.personalRecord.upsert.mockImplementation(({ create }) =>
      Promise.resolve({ id: 'pr-1', ...create, exercise: { id: 'exercise-1' } }),
    );

    const broken = await service.detectAndRecord('user-1', 'session-1');

    const volume = broken.find((r) => r.type === PersonalRecordType.MAX_VOLUME);
    expect(volume!.value).toBe(8 * 60 + 8 * 65 + 8 * 67.5);
  });

  it('does not overwrite an existing record when the new value does not beat it', async () => {
    // A single set carrying both reps and weight yields three candidates
    // (MAX_WEIGHT, MAX_REPS, MAX_VOLUME) — every one of them must already
    // have an unbeatable existing record for "nothing breaks" to hold.
    prisma.workoutSet.findMany.mockResolvedValue([set({ reps: 5, weightKg: 50 })]);
    prisma.personalRecord.findUnique.mockImplementation(({ where }) =>
      Promise.resolve({ id: 'existing', value: 999_999, type: where.userId_exerciseId_type.type }),
    );

    const broken = await service.detectAndRecord('user-1', 'session-1');

    expect(broken).toHaveLength(0);
    expect(prisma.personalRecord.upsert).not.toHaveBeenCalled();
  });

  it('updates a record in place (not append-only) when a new best is set', async () => {
    prisma.workoutSet.findMany.mockResolvedValue([set({ reps: 5, weightKg: 90 })]);
    prisma.personalRecord.findUnique.mockImplementation(({ where }) =>
      where.userId_exerciseId_type.type === PersonalRecordType.MAX_WEIGHT
        ? Promise.resolve({ id: 'existing', value: 80, type: PersonalRecordType.MAX_WEIGHT })
        : Promise.resolve(null),
    );
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
    prisma.personalRecord.findUnique.mockResolvedValue(null);
    prisma.personalRecord.upsert.mockImplementation(({ create }) =>
      Promise.resolve({ id: 'pr-1', ...create, exercise: { id: 'exercise-1' } }),
    );

    const broken = await service.detectAndRecord('user-1', 'session-1');

    expect(broken.some((r) => r.type === PersonalRecordType.MAX_VOLUME)).toBe(false);
    expect(broken.some((r) => r.type === PersonalRecordType.MAX_DURATION)).toBe(true);
  });
});
