import { Test } from '@nestjs/testing';
import { AchievementCategory } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AchievementsService } from './achievements.service';

function achievement(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'achievement-1',
    key: 'first_workout',
    title: 'First Steps',
    description: 'Complete your first workout.',
    iconAsset: 'fitness_center',
    category: AchievementCategory.WORKOUT,
    targetSteps: 1,
    createdAt: new Date(),
    ...overrides,
  };
}

describe('AchievementsService', () => {
  let service: AchievementsService;
  let prisma: {
    achievement: { findMany: jest.Mock };
    achievementAward: { findMany: jest.Mock; upsert: jest.Mock };
    workoutSession: { count: jest.Mock; findMany: jest.Mock };
    personalRecord: { count: jest.Mock };
    mealEntry: { count: jest.Mock };
    cardioSession: { count: jest.Mock };
  };

  beforeEach(async () => {
    prisma = {
      achievement: { findMany: jest.fn() },
      achievementAward: { findMany: jest.fn(), upsert: jest.fn() },
      workoutSession: { count: jest.fn(), findMany: jest.fn() },
      personalRecord: { count: jest.fn() },
      mealEntry: { count: jest.fn() },
      cardioSession: { count: jest.fn() },
    };

    const moduleRef = await Test.createTestingModule({
      providers: [AchievementsService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = moduleRef.get(AchievementsService);
  });

  describe('listForUser', () => {
    it('merges the catalog with the user’s award progress, defaulting to unearned', async () => {
      prisma.achievement.findMany.mockResolvedValue([achievement()]);
      prisma.achievementAward.findMany.mockResolvedValue([]);

      const result = await service.listForUser('user-1');

      expect(result).toEqual([
        expect.objectContaining({ key: 'first_workout', progress: 0, earnedAt: null }),
      ]);
    });

    it('reflects an existing award’s progress and earned date', async () => {
      const earnedAt = new Date('2026-08-01T00:00:00.000Z');
      prisma.achievement.findMany.mockResolvedValue([achievement()]);
      prisma.achievementAward.findMany.mockResolvedValue([
        { achievementId: 'achievement-1', progress: 1, earnedAt },
      ]);

      const result = await service.listForUser('user-1');

      expect(result[0].progress).toBe(1);
      expect(result[0].earnedAt).toEqual(earnedAt);
    });
  });

  describe('evaluateWorkoutAchievements', () => {
    it('awards a newly-earned achievement exactly once', async () => {
      prisma.workoutSession.count.mockResolvedValue(1);
      prisma.workoutSession.findMany.mockResolvedValue([{ completedAt: new Date() }]);
      prisma.personalRecord.count.mockResolvedValue(0);
      prisma.achievement.findMany.mockResolvedValue([achievement()]);
      prisma.achievementAward.findMany.mockResolvedValue([]);
      prisma.achievementAward.upsert.mockResolvedValue({
        progress: 1,
        earnedAt: new Date('2026-08-06T00:00:00.000Z'),
      });

      const result = await service.evaluateWorkoutAchievements('user-1');

      expect(result).toHaveLength(1);
      expect(result[0].key).toBe('first_workout');
      expect(prisma.achievementAward.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { userId_achievementId: { userId: 'user-1', achievementId: 'achievement-1' } },
        }),
      );
    });

    it('is idempotent: an already-earned achievement is never re-awarded', async () => {
      prisma.workoutSession.count.mockResolvedValue(5);
      prisma.workoutSession.findMany.mockResolvedValue([]);
      prisma.personalRecord.count.mockResolvedValue(0);
      prisma.achievement.findMany.mockResolvedValue([achievement()]);
      prisma.achievementAward.findMany.mockResolvedValue([
        { achievementId: 'achievement-1', progress: 1, earnedAt: new Date('2026-08-01') },
      ]);

      const result = await service.evaluateWorkoutAchievements('user-1');

      expect(result).toEqual([]);
      expect(prisma.achievementAward.upsert).not.toHaveBeenCalled();
    });

    it('does not award a still-locked, in-progress achievement', async () => {
      prisma.workoutSession.count.mockResolvedValue(3);
      prisma.workoutSession.findMany.mockResolvedValue([]);
      prisma.personalRecord.count.mockResolvedValue(0);
      prisma.achievement.findMany.mockResolvedValue([
        achievement({ key: 'ten_workouts', targetSteps: 10 }),
      ]);
      prisma.achievementAward.findMany.mockResolvedValue([]);
      prisma.achievementAward.upsert.mockResolvedValue({ progress: 3, earnedAt: null });

      const result = await service.evaluateWorkoutAchievements('user-1');

      expect(result).toEqual([]);
      expect(prisma.achievementAward.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          create: expect.objectContaining({ progress: 3, earnedAt: null }),
        }),
      );
    });
  });

  describe('evaluateNutritionAchievements', () => {
    it('awards the first-meal-logged achievement', async () => {
      prisma.mealEntry.count.mockResolvedValue(1);
      prisma.achievement.findMany.mockResolvedValue([
        achievement({
          key: 'first_meal_logged',
          category: AchievementCategory.NUTRITION,
          targetSteps: 1,
        }),
      ]);
      prisma.achievementAward.findMany.mockResolvedValue([]);
      prisma.achievementAward.upsert.mockResolvedValue({
        progress: 1,
        earnedAt: new Date('2026-08-06'),
      });

      const result = await service.evaluateNutritionAchievements('user-1');

      expect(result).toHaveLength(1);
      expect(result[0].key).toBe('first_meal_logged');
    });
  });

  describe('evaluateCardioAchievements', () => {
    it('awards the first-cardio-session achievement', async () => {
      prisma.cardioSession.count.mockResolvedValue(1);
      prisma.achievement.findMany.mockResolvedValue([
        achievement({
          key: 'first_cardio_session',
          category: AchievementCategory.CARDIO,
          targetSteps: 1,
        }),
      ]);
      prisma.achievementAward.findMany.mockResolvedValue([]);
      prisma.achievementAward.upsert.mockResolvedValue({
        progress: 1,
        earnedAt: new Date('2026-08-06'),
      });

      const result = await service.evaluateCardioAchievements('user-1');

      expect(result).toHaveLength(1);
      expect(result[0].key).toBe('first_cardio_session');
    });
  });
});
