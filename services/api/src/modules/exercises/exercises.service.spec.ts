import { NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { ExercisesService } from './exercises.service';

describe('ExercisesService', () => {
  let service: ExercisesService;
  let prisma: {
    exercise: { findMany: jest.Mock; findUnique: jest.Mock };
    workoutSession: { findFirst: jest.Mock };
  };

  beforeEach(async () => {
    prisma = {
      exercise: { findMany: jest.fn(), findUnique: jest.fn() },
      workoutSession: { findFirst: jest.fn() },
    };

    const moduleRef = await Test.createTestingModule({
      providers: [ExercisesService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = moduleRef.get(ExercisesService);
  });

  describe('getProgressionSuggestion', () => {
    it('rejects an unknown exercise', async () => {
      prisma.exercise.findUnique.mockResolvedValue(null);

      await expect(service.getProgressionSuggestion('user-1', 'missing')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('reports no previous performance when the user has never completed this exercise', async () => {
      prisma.exercise.findUnique.mockResolvedValue({ id: 'exercise-1' });
      prisma.workoutSession.findFirst.mockResolvedValue(null);

      const result = await service.getProgressionSuggestion('user-1', 'exercise-1');

      expect(result).toEqual({ exerciseId: 'exercise-1', hasPreviousPerformance: false });
    });

    it('suggests a modest weight increase over the last completed weighted set', async () => {
      prisma.exercise.findUnique.mockResolvedValue({ id: 'exercise-1' });
      prisma.workoutSession.findFirst.mockResolvedValue({
        sets: [
          {
            reps: 8,
            weightKg: 60,
            durationSeconds: null,
            distanceMeters: null,
            completedAt: new Date(),
          },
        ],
      });

      const result = await service.getProgressionSuggestion('user-1', 'exercise-1');

      expect(result.hasPreviousPerformance).toBe(true);
      expect(result.suggestion!.weightKg).toBeGreaterThan(60);
      expect(result.suggestion!.reps).toBe(8);
    });

    it('always suggests a strictly higher weight even when the % increase rounds down to the same value', async () => {
      // 20kg * 1.025 = 20.5, rounded to the nearest 2.5kg increment is 20 —
      // the suggestion must still move, not silently repeat last time.
      prisma.exercise.findUnique.mockResolvedValue({ id: 'exercise-1' });
      prisma.workoutSession.findFirst.mockResolvedValue({
        sets: [
          {
            reps: 12,
            weightKg: 20,
            durationSeconds: null,
            distanceMeters: null,
            completedAt: new Date(),
          },
        ],
      });

      const result = await service.getProgressionSuggestion('user-1', 'exercise-1');

      expect(result.suggestion!.weightKg).toBeGreaterThan(20);
    });

    it('suggests one more rep when the exercise is bodyweight (no weight logged)', async () => {
      prisma.exercise.findUnique.mockResolvedValue({ id: 'exercise-1' });
      prisma.workoutSession.findFirst.mockResolvedValue({
        sets: [
          {
            reps: 15,
            weightKg: null,
            durationSeconds: null,
            distanceMeters: null,
            completedAt: new Date(),
          },
        ],
      });

      const result = await service.getProgressionSuggestion('user-1', 'exercise-1');

      expect(result.suggestion).toEqual(expect.objectContaining({ reps: 16, weightKg: null }));
    });

    it('suggests a longer duration for a duration-based exercise', async () => {
      prisma.exercise.findUnique.mockResolvedValue({ id: 'exercise-1' });
      prisma.workoutSession.findFirst.mockResolvedValue({
        sets: [
          {
            reps: null,
            weightKg: null,
            durationSeconds: 45,
            distanceMeters: null,
            completedAt: new Date(),
          },
        ],
      });

      const result = await service.getProgressionSuggestion('user-1', 'exercise-1');

      expect(result.suggestion!.durationSeconds).toBeGreaterThan(45);
    });
  });
});
