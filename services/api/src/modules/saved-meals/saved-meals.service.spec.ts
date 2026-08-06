import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { MealType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NutritionLogService } from '../nutrition-log/nutrition-log.service';
import { SavedMealsService } from './saved-meals.service';

describe('SavedMealsService', () => {
  let service: SavedMealsService;
  let prisma: {
    savedMeal: {
      findMany: jest.Mock;
      findUnique: jest.Mock;
      create: jest.Mock;
      delete: jest.Mock;
    };
  };
  let nutritionLogService: { addEntry: jest.Mock };

  function savedMeal(overrides: Partial<Record<string, unknown>> = {}) {
    return {
      id: 'saved-meal-1',
      userId: 'user-1',
      name: 'Breakfast staple',
      createdAt: new Date(),
      items: [
        {
          id: 'item-1',
          foodId: 'food-1',
          foodServingId: null,
          quantity: 2,
          food: { id: 'food-1', name: 'Egg', brand: null, isEstimated: true },
          foodServing: null,
        },
      ],
      ...overrides,
    };
  }

  beforeEach(async () => {
    prisma = {
      savedMeal: {
        findMany: jest.fn(),
        findUnique: jest.fn(),
        create: jest.fn(),
        delete: jest.fn(),
      },
    };
    nutritionLogService = { addEntry: jest.fn() };

    const moduleRef = await Test.createTestingModule({
      providers: [
        SavedMealsService,
        { provide: PrismaService, useValue: prisma },
        { provide: NutritionLogService, useValue: nutritionLogService },
      ],
    }).compile();

    service = moduleRef.get(SavedMealsService);
  });

  it('lists a user’s saved meals with resolved items', async () => {
    prisma.savedMeal.findMany.mockResolvedValue([savedMeal()]);

    const result = await service.list('user-1');

    expect(result).toHaveLength(1);
    expect(result[0].items[0].food.name).toBe('Egg');
  });

  it('creates a saved meal with its items in one write', async () => {
    prisma.savedMeal.create.mockResolvedValue(savedMeal());

    await service.create('user-1', {
      name: 'Breakfast staple',
      items: [{ foodId: 'food-1', quantity: 2 }],
    });

    expect(prisma.savedMeal.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          userId: 'user-1',
          name: 'Breakfast staple',
          items: { create: [{ foodId: 'food-1', foodServingId: undefined, quantity: 2 }] },
        }),
      }),
    );
  });

  it('logs every item through NutritionLogService.addEntry, never duplicating its macro math', async () => {
    prisma.savedMeal.findUnique.mockResolvedValue(savedMeal());
    nutritionLogService.addEntry.mockResolvedValue({ id: 'entry-1' });

    const result = await service.logMeal('user-1', 'saved-meal-1', {
      mealType: MealType.BREAKFAST,
      date: '2026-08-06',
      idempotencyKey: 'log-key',
    });

    expect(nutritionLogService.addEntry).toHaveBeenCalledWith('user-1', {
      foodId: 'food-1',
      foodServingId: undefined,
      mealType: MealType.BREAKFAST,
      date: '2026-08-06',
      quantity: 2,
      idempotencyKey: 'log-key-item-1',
    });
    expect(result).toEqual([{ id: 'entry-1' }]);
  });

  it('rejects logging a saved meal owned by another user', async () => {
    prisma.savedMeal.findUnique.mockResolvedValue(savedMeal({ userId: 'someone-else' }));

    await expect(
      service.logMeal('user-1', 'saved-meal-1', { mealType: MealType.LUNCH, date: '2026-08-06' }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(nutritionLogService.addEntry).not.toHaveBeenCalled();
  });

  it('rejects acting on a saved meal that does not exist', async () => {
    prisma.savedMeal.findUnique.mockResolvedValue(null);

    await expect(service.delete('user-1', 'missing')).rejects.toBeInstanceOf(NotFoundException);
  });
});
