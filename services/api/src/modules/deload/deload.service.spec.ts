import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { DeloadService } from './deload.service';

describe('DeloadService', () => {
  let service: DeloadService;
  let prisma: {
    deloadRecommendation: {
      findFirst: jest.Mock;
      findUnique: jest.Mock;
      create: jest.Mock;
      update: jest.Mock;
    };
    workoutSession: { findMany: jest.Mock };
  };

  const now = new Date('2026-08-06T12:00:00Z');

  function daysAgo(days: number): Date {
    return new Date(now.getTime() - days * 24 * 60 * 60 * 1000);
  }

  function session(completedAt: Date, rpes: (number | null)[]) {
    return { completedAt, sets: rpes.map((rpe) => ({ rpe })) };
  }

  beforeEach(async () => {
    prisma = {
      deloadRecommendation: {
        findFirst: jest.fn(),
        findUnique: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      workoutSession: { findMany: jest.fn() },
    };

    const moduleRef = await Test.createTestingModule({
      providers: [DeloadService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = moduleRef.get(DeloadService);
  });

  it('returns an already-active recommendation instead of recomputing', async () => {
    prisma.deloadRecommendation.findFirst.mockResolvedValueOnce({ id: 'existing' });

    const result = await service.getActiveRecommendation('user-1', now);

    expect(result).toEqual({ id: 'existing' });
    expect(prisma.workoutSession.findMany).not.toHaveBeenCalled();
  });

  it('creates a recommendation after 6+ consecutive weeks of training with recent high RPE', async () => {
    prisma.deloadRecommendation.findFirst
      .mockResolvedValueOnce(null) // no active recommendation
      .mockResolvedValueOnce(null); // no recent evaluation to respect the cooldown
    prisma.workoutSession.findMany.mockResolvedValue([
      session(daysAgo(0), [9, 8.5]),
      session(daysAgo(7), [8]),
      session(daysAgo(14), [7]),
      session(daysAgo(21), [7]),
      session(daysAgo(28), [7]),
      session(daysAgo(35), [7]),
    ]);
    prisma.deloadRecommendation.create.mockResolvedValue({ id: 'new-rec' });

    const result = await service.getActiveRecommendation('user-1', now);

    expect(prisma.deloadRecommendation.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ userId: 'user-1' }) }),
    );
    expect(result).toEqual({ id: 'new-rec' });
  });

  it('does not suggest a deload with fewer than 6 consecutive weeks trained', async () => {
    prisma.deloadRecommendation.findFirst.mockResolvedValueOnce(null).mockResolvedValueOnce(null);
    prisma.workoutSession.findMany.mockResolvedValue([
      session(daysAgo(0), [9]),
      session(daysAgo(7), [9]),
    ]);

    const result = await service.getActiveRecommendation('user-1', now);

    expect(result).toBeNull();
    expect(prisma.deloadRecommendation.create).not.toHaveBeenCalled();
  });

  it('does not suggest a deload when consistent but recent effort is not high', async () => {
    prisma.deloadRecommendation.findFirst.mockResolvedValueOnce(null).mockResolvedValueOnce(null);
    prisma.workoutSession.findMany.mockResolvedValue([
      session(daysAgo(0), [5]),
      session(daysAgo(7), [5]),
      session(daysAgo(14), [5]),
      session(daysAgo(21), [5]),
      session(daysAgo(28), [5]),
      session(daysAgo(35), [5]),
    ]);

    const result = await service.getActiveRecommendation('user-1', now);

    expect(result).toBeNull();
    expect(prisma.deloadRecommendation.create).not.toHaveBeenCalled();
  });

  it('never re-evaluates within the cooldown window, even if signals now qualify (anti-nagging)', async () => {
    prisma.deloadRecommendation.findFirst
      .mockResolvedValueOnce(null) // no active recommendation
      .mockResolvedValueOnce({ id: 'recently-evaluated' }); // but evaluated recently

    const result = await service.getActiveRecommendation('user-1', now);

    expect(result).toBeNull();
    expect(prisma.workoutSession.findMany).not.toHaveBeenCalled();
    expect(prisma.deloadRecommendation.create).not.toHaveBeenCalled();
  });

  it('dismiss sets dismissedAt on a recommendation owned by the user', async () => {
    prisma.deloadRecommendation.findUnique.mockResolvedValue({ id: 'rec-1', userId: 'user-1' });
    prisma.deloadRecommendation.update.mockResolvedValue({ id: 'rec-1', dismissedAt: now });

    await service.dismiss('user-1', 'rec-1');

    expect(prisma.deloadRecommendation.update).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'rec-1' } }),
    );
  });

  it('rejects dismissing a recommendation that belongs to another user', async () => {
    prisma.deloadRecommendation.findUnique.mockResolvedValue({
      id: 'rec-1',
      userId: 'someone-else',
    });

    await expect(service.dismiss('user-1', 'rec-1')).rejects.toBeInstanceOf(ForbiddenException);
    expect(prisma.deloadRecommendation.update).not.toHaveBeenCalled();
  });

  it('rejects acting on a recommendation that does not exist', async () => {
    prisma.deloadRecommendation.findUnique.mockResolvedValue(null);

    await expect(service.postpone('user-1', 'missing', 7)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });
});
