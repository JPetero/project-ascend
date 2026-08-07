import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { DataExportService } from './data-export.service';

function makePrismaMock() {
  return {
    user: { findUnique: jest.fn().mockResolvedValue({ id: 'user-1', email: 'a@example.com' }) },
    profile: { findUnique: jest.fn().mockResolvedValue({ firstName: 'Ada' }) },
    preference: { findUnique: jest.fn().mockResolvedValue({ themeMode: 'SYSTEM' }) },
    notificationPreference: { findUnique: jest.fn().mockResolvedValue(null) },
    workoutSession: { findMany: jest.fn().mockResolvedValue([{ id: 'session-1' }]) },
    personalRecord: { findMany: jest.fn().mockResolvedValue([]) },
    mealEntry: { findMany: jest.fn().mockResolvedValue([]) },
    waterEntry: { findMany: jest.fn().mockResolvedValue([]) },
    macroTarget: { findUnique: jest.fn().mockResolvedValue(null) },
    savedMeal: { findMany: jest.fn().mockResolvedValue([]) },
    cardioSession: { findMany: jest.fn().mockResolvedValue([]) },
    healthMetricSample: { findMany: jest.fn().mockResolvedValue([]) },
    achievementAward: { findMany: jest.fn().mockResolvedValue([]) },
    communityProfile: { findUnique: jest.fn().mockResolvedValue(null) },
    communityPost: { findMany: jest.fn().mockResolvedValue([]) },
    friendship: { findMany: jest.fn().mockResolvedValue([]) },
    directMessage: { findMany: jest.fn().mockResolvedValue([]) },
    savedNutrientArticle: { findMany: jest.fn().mockResolvedValue([]) },
  };
}

describe('DataExportService', () => {
  it('scopes every query to the requesting user and shapes the export', async () => {
    const prisma = makePrismaMock();
    const moduleRef = await Test.createTestingModule({
      providers: [DataExportService, { provide: PrismaService, useValue: prisma }],
    }).compile();
    const service = moduleRef.get(DataExportService);

    const result = await service.exportMyData('user-1');

    expect(prisma.user.findUnique).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'user-1' } }),
    );
    expect(prisma.workoutSession.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { userId: 'user-1', status: 'COMPLETED' } }),
    );
    expect(result.account.email).toBe('a@example.com');
    expect(result.account.profile).toEqual({ firstName: 'Ada' });
    expect(result.fitness.completedWorkoutSessions).toEqual([{ id: 'session-1' }]);
    expect(result.exportedAt).toBeDefined();
  });

  it('merges friendships from both sides of the relation into one id list', async () => {
    const prisma = makePrismaMock();
    prisma.friendship.findMany = jest
      .fn()
      .mockResolvedValueOnce([{ userAId: 'user-1', userBId: 'friend-a' }])
      .mockResolvedValueOnce([{ userAId: 'friend-b', userBId: 'user-1' }]);
    const moduleRef = await Test.createTestingModule({
      providers: [DataExportService, { provide: PrismaService, useValue: prisma }],
    }).compile();
    const service = moduleRef.get(DataExportService);

    const result = await service.exportMyData('user-1');

    expect(result.social.friendIds).toEqual(['friend-a', 'friend-b']);
  });
});
