import { NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { CardioActivityType } from '@prisma/client';
import { IdempotencyService } from '../../common/idempotency/idempotency.service';
import { PrismaService } from '../../prisma/prisma.service';
import { AchievementsService } from '../achievements/achievements.service';
import { CardioService } from './cardio.service';

function cardioSession(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'cardio-1',
    userId: 'user-1',
    activityType: CardioActivityType.RUN,
    startedAt: new Date('2026-08-06T08:00:00.000Z'),
    durationSeconds: 1800,
    distanceMeters: 5000,
    elevationGainMeters: null,
    estimatedCalories: 350,
    regionLabel: 'Quezon City',
    hideRoute: true,
    hideStartLocation: true,
    hideEndLocation: true,
    notes: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

describe('CardioService', () => {
  let service: CardioService;
  let prisma: {
    cardioSession: {
      create: jest.Mock;
      findMany: jest.Mock;
      count: jest.Mock;
      findUnique: jest.Mock;
      update: jest.Mock;
      delete: jest.Mock;
    };
  };
  let achievementsService: { evaluateCardioAchievements: jest.Mock };
  let idempotencyService: { run: jest.Mock };

  beforeEach(async () => {
    prisma = {
      cardioSession: {
        create: jest.fn(),
        findMany: jest.fn(),
        count: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
      },
    };
    achievementsService = { evaluateCardioAchievements: jest.fn() };
    idempotencyService = { run: jest.fn() };

    const moduleRef = await Test.createTestingModule({
      providers: [
        CardioService,
        { provide: PrismaService, useValue: prisma },
        { provide: IdempotencyService, useValue: idempotencyService },
        { provide: AchievementsService, useValue: achievementsService },
      ],
    }).compile();

    service = moduleRef.get(CardioService);
  });

  it('creates a cardio session, defaulting privacy flags to hidden', async () => {
    prisma.cardioSession.create.mockResolvedValue(cardioSession());

    const result = await service.create('user-1', {
      activityType: CardioActivityType.RUN,
      startedAt: '2026-08-06T08:00:00.000Z',
      durationSeconds: 1800,
      distanceMeters: 5000,
    });

    expect(prisma.cardioSession.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          userId: 'user-1',
          hideRoute: true,
          hideStartLocation: true,
          hideEndLocation: true,
        }),
      }),
    );
    expect(result.id).toBe('cardio-1');
  });

  it('evaluates cardio achievements idempotently after every log', async () => {
    prisma.cardioSession.create.mockResolvedValue(cardioSession());

    await service.create('user-1', {
      activityType: CardioActivityType.WALK,
      startedAt: '2026-08-06T08:00:00.000Z',
      durationSeconds: 900,
    });

    expect(achievementsService.evaluateCardioAchievements).toHaveBeenCalledWith('user-1');
  });

  it('respects explicit privacy overrides', async () => {
    prisma.cardioSession.create.mockResolvedValue(cardioSession({ hideRoute: false }));

    await service.create('user-1', {
      activityType: CardioActivityType.CYCLE,
      startedAt: '2026-08-06T08:00:00.000Z',
      durationSeconds: 3600,
      hideRoute: false,
    });

    expect(prisma.cardioSession.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ hideRoute: false }) }),
    );
  });

  it('paginates a user’s cardio sessions, most recent first', async () => {
    prisma.cardioSession.findMany.mockResolvedValue([cardioSession()]);
    prisma.cardioSession.count.mockResolvedValue(1);

    const result = await service.list('user-1', { page: 1, limit: 20 });

    expect(result.data).toHaveLength(1);
    expect(result.meta).toEqual({ page: 1, limit: 20, total: 1 });
    expect(prisma.cardioSession.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ orderBy: { startedAt: 'desc' } }),
    );
  });

  it('rejects reading, updating, or deleting a session owned by another user', async () => {
    prisma.cardioSession.findUnique.mockResolvedValue(cardioSession({ userId: 'someone-else' }));

    await expect(service.getById('user-1', 'cardio-1')).rejects.toBeInstanceOf(NotFoundException);
    await expect(service.update('user-1', 'cardio-1', { hideRoute: false })).rejects.toBeInstanceOf(
      NotFoundException,
    );
    await expect(service.delete('user-1', 'cardio-1')).rejects.toBeInstanceOf(NotFoundException);
  });

  it('updates only the privacy flags and notes, never the recorded activity', async () => {
    prisma.cardioSession.findUnique.mockResolvedValue(cardioSession());
    prisma.cardioSession.update.mockResolvedValue(
      cardioSession({ hideRoute: false, notes: 'Felt great' }),
    );

    await service.update('user-1', 'cardio-1', { hideRoute: false, notes: 'Felt great' });

    expect(prisma.cardioSession.update).toHaveBeenCalledWith({
      where: { id: 'cardio-1' },
      data: { hideRoute: false, notes: 'Felt great' },
    });
  });
});
