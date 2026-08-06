import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { IdempotencyService } from '../../common/idempotency/idempotency.service';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateMealEntryDto } from '../nutrition-log/dto/create-meal-entry.dto';
import { NutritionLogService } from '../nutrition-log/nutrition-log.service';
import { CreateSavedMealDto } from './dto/create-saved-meal.dto';
import { LogSavedMealDto } from './dto/log-saved-meal.dto';
import { UpdateSavedMealDto } from './dto/update-saved-meal.dto';

const savedMealInclude = {
  items: {
    include: {
      food: { select: { id: true, name: true, brand: true, isEstimated: true } },
      foodServing: { select: { id: true, label: true } },
    },
  },
} satisfies Prisma.SavedMealInclude;

type SavedMealWithItems = Prisma.SavedMealGetPayload<{ include: typeof savedMealInclude }>;

/**
 * A named, reusable group of food entries — see
 * packages/docs/product/user-scenario-bible.md Part 7 (Meal Prep). Logging
 * a saved meal reuses NutritionLogService.addEntry for every item rather
 * than re-deriving the calorie/macro-snapshot math, so both paths stay in
 * agreement by construction (see engineering-bible.md's "don't duplicate
 * logic" rule).
 */
@Injectable()
export class SavedMealsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly nutritionLogService: NutritionLogService,
    private readonly idempotencyService: IdempotencyService,
  ) {}

  async list(userId: string) {
    const savedMeals = await this.prisma.savedMeal.findMany({
      where: { userId },
      include: savedMealInclude,
      orderBy: { createdAt: 'desc' },
    });
    return savedMeals.map((m) => this.serialize(m));
  }

  async create(userId: string, dto: CreateSavedMealDto) {
    const run = async () => {
      const savedMeal = await this.prisma.savedMeal.create({
        data: {
          userId,
          name: dto.name,
          items: {
            create: dto.items.map((item) => ({
              foodId: item.foodId,
              foodServingId: item.foodServingId,
              quantity: item.quantity,
            })),
          },
        },
        include: savedMealInclude,
      });
      const payload = this.serialize(savedMeal);
      return { entityId: payload.id, payload };
    };

    if (dto.idempotencyKey) {
      return this.idempotencyService.run(
        {
          userId,
          idempotencyKey: dto.idempotencyKey,
          entityType: 'SAVED_MEAL',
          operationType: 'CREATE',
        },
        run,
      );
    }
    return (await run()).payload;
  }

  /** Replaces the name and/or the full item list — see UpdateSavedMealDto. */
  async update(userId: string, id: string, dto: UpdateSavedMealDto) {
    await this.findOwned(userId, id);

    await this.prisma.$transaction(async (tx) => {
      if (dto.items) {
        await tx.savedMealItem.deleteMany({ where: { savedMealId: id } });
        await tx.savedMealItem.createMany({
          data: dto.items.map((item) => ({
            savedMealId: id,
            foodId: item.foodId,
            foodServingId: item.foodServingId,
            quantity: item.quantity,
          })),
        });
      }
      if (dto.name !== undefined) {
        await tx.savedMeal.update({ where: { id }, data: { name: dto.name } });
      }
    });

    const updated = await this.findOwned(userId, id);
    return this.serialize(updated);
  }

  async delete(userId: string, id: string): Promise<void> {
    await this.findOwned(userId, id);
    await this.prisma.savedMeal.delete({ where: { id } });
  }

  /** Logs every item in the saved meal as its own MealEntry for the given
   * date/mealType — a real, separately-editable/deletable entry each, not
   * a linked reference back to the SavedMeal. Returns the same
   * `{ data, meta, error }` shape `NutritionLogService.addEntry` does:
   * `data` is the list of created entries (unchanged from before this
   * session), `meta.newAchievements` aggregates anything newly earned
   * across every item logged (deduplicated — evaluating the same
   * achievement twice in one call is a harmless idempotent no-op, but
   * only the first evaluation actually returns it as "new"). */
  async logMeal(userId: string, id: string, dto: LogSavedMealDto) {
    const savedMeal = await this.findOwned(userId, id);

    const created = [];
    const newAchievements = [];
    for (const item of savedMeal.items) {
      const entryDto: CreateMealEntryDto = {
        foodId: item.foodId,
        foodServingId: item.foodServingId ?? undefined,
        mealType: dto.mealType,
        date: dto.date,
        quantity: item.quantity,
        idempotencyKey: dto.idempotencyKey ? `${dto.idempotencyKey}-${item.id}` : undefined,
      };
      const result = await this.nutritionLogService.addEntry(userId, entryDto);
      created.push(result.data);
      newAchievements.push(...((result.meta.newAchievements as unknown[]) ?? []));
    }
    return { data: created, meta: { newAchievements }, error: null };
  }

  private async findOwned(userId: string, id: string): Promise<SavedMealWithItems> {
    const savedMeal = await this.prisma.savedMeal.findUnique({
      where: { id },
      include: savedMealInclude,
    });
    if (!savedMeal) {
      throw new NotFoundException('Saved meal not found.');
    }
    if (savedMeal.userId !== userId) {
      throw new ForbiddenException();
    }
    return savedMeal;
  }

  private serialize(savedMeal: SavedMealWithItems) {
    return {
      id: savedMeal.id,
      name: savedMeal.name,
      createdAt: savedMeal.createdAt,
      items: savedMeal.items.map((item) => ({
        id: item.id,
        food: item.food,
        foodServing: item.foodServing,
        quantity: item.quantity,
      })),
    };
  }
}
