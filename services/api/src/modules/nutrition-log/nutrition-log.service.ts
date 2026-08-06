import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { FoodSourceType, Prisma } from '@prisma/client';
import { IdempotencyService } from '../../common/idempotency/idempotency.service';
import { PrismaService } from '../../prisma/prisma.service';
import { AchievementsService } from '../achievements/achievements.service';
import { CopyMealEntriesDto } from './dto/copy-meal-entries.dto';
import { CreateMealEntryDto } from './dto/create-meal-entry.dto';
import { UpdateMealEntryDto } from './dto/update-meal-entry.dto';

const entryInclude = {
  food: { select: { id: true, name: true, brand: true, isEstimated: true } },
  foodServing: { select: { id: true, label: true } },
} satisfies Prisma.MealEntryInclude;

type EntryWithRelations = Prisma.MealEntryGetPayload<{ include: typeof entryInclude }>;

/** Rounds to one decimal place — consistent handling everywhere a macro
 * value is computed or summed, so repeated additions never drift into
 * long floating-point tails (e.g. `0.1 + 0.2`). */
function round1(value: number): number {
  return Math.round(value * 10) / 10;
}

function parseDateOnly(date: string): Date {
  return new Date(`${date}T00:00:00.000Z`);
}

@Injectable()
export class NutritionLogService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly idempotencyService: IdempotencyService,
    private readonly achievementsService: AchievementsService,
  ) {}

  async getDaily(userId: string, date: string) {
    const entries = await this.prisma.mealEntry.findMany({
      where: { userId, date: parseDateOnly(date) },
      include: entryInclude,
      orderBy: { createdAt: 'asc' },
    });
    return entries.map((e) => this.serialize(e));
  }

  async getDailySummary(userId: string, date: string) {
    const entries = await this.prisma.mealEntry.findMany({
      where: { userId, date: parseDateOnly(date) },
    });
    return { date, ...this.sumMacros(entries) };
  }

  async getSevenDaySummary(userId: string, endDate: string) {
    const end = parseDateOnly(endDate);
    const start = new Date(end);
    start.setUTCDate(start.getUTCDate() - 6);

    const entries = await this.prisma.mealEntry.findMany({
      where: { userId, date: { gte: start, lte: end } },
    });

    const days: Array<{ date: string } & ReturnType<typeof this.sumMacros>> = [];
    for (let i = 0; i < 7; i++) {
      const day = new Date(start);
      day.setUTCDate(day.getUTCDate() + i);
      const dayStr = day.toISOString().slice(0, 10);
      const dayEntries = entries.filter((e) => e.date.toISOString().slice(0, 10) === dayStr);
      days.push({ date: dayStr, ...this.sumMacros(dayEntries) });
    }

    const totalDays = days.length;
    const average = {
      calories: round1(days.reduce((sum, d) => sum + d.calories, 0) / totalDays),
      proteinGrams: round1(days.reduce((sum, d) => sum + d.proteinGrams, 0) / totalDays),
      carbGrams: round1(days.reduce((sum, d) => sum + d.carbGrams, 0) / totalDays),
      fatGrams: round1(days.reduce((sum, d) => sum + d.fatGrams, 0) / totalDays),
      fiberGrams: round1(days.reduce((sum, d) => sum + d.fiberGrams, 0) / totalDays),
    };

    return { startDate: start.toISOString().slice(0, 10), endDate: endDate, days, average };
  }

  /**
   * Returns a full `{ data, meta, error }` envelope rather than the plain
   * entry: `data` stays exactly the serialized entry (unchanged shape for
   * every existing caller), while `meta.newAchievements` additively
   * carries any achievement newly earned by this log — the same
   * "celebrate at the moment it's earned" contract `WorkoutSessionsService
   * .finish()` already honors. See `ResponseEnvelopeInterceptor`: a
   * service returning this exact shape is passed through unwrapped.
   */
  async addEntry(userId: string, dto: CreateMealEntryDto) {
    const run = async () => {
      const result = await this.createEntry(userId, dto);
      return { entityId: result.entry.id, payload: result };
    };

    const result = dto.idempotencyKey
      ? await this.idempotencyService.run(
          {
            userId,
            idempotencyKey: dto.idempotencyKey,
            entityType: 'MEAL_ENTRY',
            operationType: 'CREATE',
          },
          run,
        )
      : (await run()).payload;

    return { data: result.entry, meta: { newAchievements: result.newAchievements }, error: null };
  }

  async updateEntry(userId: string, id: string, dto: UpdateMealEntryDto) {
    const existing = await this.findOwned(userId, id);

    const recomputeMacros =
      dto.foodId !== undefined ||
      dto.foodServingId !== undefined ||
      dto.quantity !== undefined ||
      dto.loggedByGrams !== undefined ||
      dto.gramsLogged !== undefined;

    const macros = recomputeMacros
      ? await this.computeMacroSnapshot(userId, {
          foodId: dto.foodId ?? existing.foodId,
          foodServingId: dto.foodServingId ?? existing.foodServingId ?? undefined,
          quantity: dto.quantity ?? existing.quantity,
          loggedByGrams: dto.loggedByGrams ?? existing.loggedByGrams,
          gramsLogged: dto.gramsLogged ?? existing.gramsLogged ?? undefined,
        })
      : null;

    const updated = await this.prisma.mealEntry.update({
      where: { id },
      data: {
        ...(dto.foodId !== undefined ? { foodId: dto.foodId } : {}),
        ...(dto.foodServingId !== undefined ? { foodServingId: dto.foodServingId } : {}),
        ...(dto.mealType !== undefined ? { mealType: dto.mealType } : {}),
        ...(dto.date !== undefined ? { date: parseDateOnly(dto.date) } : {}),
        ...(dto.quantity !== undefined ? { quantity: dto.quantity } : {}),
        ...(dto.loggedByGrams !== undefined ? { loggedByGrams: dto.loggedByGrams } : {}),
        ...(dto.gramsLogged !== undefined ? { gramsLogged: dto.gramsLogged } : {}),
        ...(dto.notes !== undefined ? { notes: dto.notes } : {}),
        ...(macros ?? {}),
      },
      include: entryInclude,
    });

    return this.serialize(updated);
  }

  async deleteEntry(userId: string, id: string): Promise<void> {
    await this.findOwned(userId, id);
    await this.prisma.mealEntry.delete({ where: { id } });
  }

  async copyEntries(userId: string, dto: CopyMealEntriesDto) {
    const run = async () => {
      const source = await this.prisma.mealEntry.findMany({
        where: {
          userId,
          date: parseDateOnly(dto.sourceDate),
          ...(dto.mealType ? { mealType: dto.mealType } : {}),
        },
      });

      if (source.length === 0) {
        return { entityId: undefined, payload: [] };
      }

      const created = await this.prisma.$transaction(
        source.map((entry) =>
          this.prisma.mealEntry.create({
            data: {
              userId,
              foodId: entry.foodId,
              foodServingId: entry.foodServingId,
              mealType: entry.mealType,
              date: parseDateOnly(dto.targetDate),
              quantity: entry.quantity,
              loggedByGrams: entry.loggedByGrams,
              gramsLogged: entry.gramsLogged,
              calories: entry.calories,
              proteinGrams: entry.proteinGrams,
              carbGrams: entry.carbGrams,
              fatGrams: entry.fatGrams,
              fiberGrams: entry.fiberGrams,
              notes: entry.notes,
            },
            include: entryInclude,
          }),
        ),
      );

      return {
        entityId: undefined,
        payload: created.map((e) => this.serialize(e)),
      };
    };

    if (dto.idempotencyKey) {
      return this.idempotencyService.run(
        {
          userId,
          idempotencyKey: dto.idempotencyKey,
          entityType: 'MEAL_ENTRY_COPY',
          operationType: 'CREATE',
        },
        run,
      );
    }
    return (await run()).payload;
  }

  private async createEntry(userId: string, dto: CreateMealEntryDto) {
    const macros = await this.computeMacroSnapshot(userId, dto);

    const created = await this.prisma.mealEntry.create({
      data: {
        userId,
        foodId: dto.foodId,
        foodServingId: dto.foodServingId,
        mealType: dto.mealType,
        date: parseDateOnly(dto.date),
        quantity: dto.quantity,
        loggedByGrams: dto.loggedByGrams ?? false,
        gramsLogged: dto.gramsLogged,
        notes: dto.notes,
        ...macros,
      },
      include: entryInclude,
    });

    // Session 5 revisits the earlier "not surfaced" decision here: meal
    // logging is one of the required immediate-celebration triggers, so
    // this now flows back through `addEntry`'s envelope `meta`. The
    // idempotent upsert inside means calling this on every log stays safe
    // even on a retried/replayed request.
    const newAchievements = await this.achievementsService.evaluateNutritionAchievements(userId);

    return { entry: this.serialize(created), newAchievements };
  }

  /**
   * Resolves how many "reference servings" of the food this entry
   * represents, then scales `Food`'s per-serving macros by that multiplier
   * and rounds each field to one decimal place. Snapshotted onto the
   * `MealEntry` itself (see schema.prisma's Nutrition section comment) so
   * later edits to the `Food` never rewrite already-logged history.
   */
  private async computeMacroSnapshot(
    userId: string,
    params: {
      foodId: string;
      foodServingId?: string;
      quantity: number;
      loggedByGrams?: boolean;
      gramsLogged?: number;
    },
  ) {
    const food = await this.prisma.food.findUnique({ where: { id: params.foodId } });
    if (!food || (food.sourceType === FoodSourceType.USER && food.ownerId !== userId)) {
      throw new NotFoundException('Food not found.');
    }
    if (food.archivedAt) {
      throw new BadRequestException('This food has been archived and can no longer be logged.');
    }

    let serving: { grams: number | null } | null = null;
    if (params.foodServingId) {
      const found = await this.prisma.foodServing.findUnique({
        where: { id: params.foodServingId },
      });
      if (!found || found.foodId !== params.foodId) {
        throw new NotFoundException('Serving option not found for this food.');
      }
      serving = found;
    }

    let multiplier: number;
    if (params.loggedByGrams) {
      if (!food.servingGrams) {
        throw new BadRequestException(
          'This food does not support gram-based logging — log it by serving count instead.',
        );
      }
      if (!params.gramsLogged) {
        throw new BadRequestException('gramsLogged is required when loggedByGrams is true.');
      }
      multiplier = params.gramsLogged / food.servingGrams;
    } else if (serving?.grams && food.servingGrams) {
      multiplier = (serving.grams * params.quantity) / food.servingGrams;
    } else {
      // The serving option isn't gram-convertible (e.g. "1 piece") — the
      // quantity directly multiplies the food's own reference serving.
      multiplier = params.quantity;
    }

    return {
      calories: round1(food.caloriesPerServing * multiplier),
      proteinGrams: round1(food.proteinGramsPerServing * multiplier),
      carbGrams: round1(food.carbGramsPerServing * multiplier),
      fatGrams: round1(food.fatGramsPerServing * multiplier),
      fiberGrams:
        food.fiberGramsPerServing !== null ? round1(food.fiberGramsPerServing * multiplier) : null,
    };
  }

  private sumMacros(
    entries: Array<{
      calories: number;
      proteinGrams: number;
      carbGrams: number;
      fatGrams: number;
      fiberGrams: number | null;
    }>,
  ) {
    return {
      calories: round1(entries.reduce((sum, e) => sum + e.calories, 0)),
      proteinGrams: round1(entries.reduce((sum, e) => sum + e.proteinGrams, 0)),
      carbGrams: round1(entries.reduce((sum, e) => sum + e.carbGrams, 0)),
      fatGrams: round1(entries.reduce((sum, e) => sum + e.fatGrams, 0)),
      fiberGrams: round1(entries.reduce((sum, e) => sum + (e.fiberGrams ?? 0), 0)),
      entryCount: entries.length,
    };
  }

  private async findOwned(userId: string, id: string): Promise<EntryWithRelations> {
    const entry = await this.prisma.mealEntry.findUnique({ where: { id }, include: entryInclude });
    if (!entry || entry.userId !== userId) {
      throw new NotFoundException('Meal entry not found.');
    }
    return entry;
  }

  private serialize(entry: EntryWithRelations) {
    return {
      id: entry.id,
      food: entry.food,
      foodServing: entry.foodServing,
      mealType: entry.mealType,
      date: entry.date.toISOString().slice(0, 10),
      quantity: entry.quantity,
      loggedByGrams: entry.loggedByGrams,
      gramsLogged: entry.gramsLogged,
      calories: entry.calories,
      proteinGrams: entry.proteinGrams,
      carbGrams: entry.carbGrams,
      fatGrams: entry.fatGrams,
      fiberGrams: entry.fiberGrams,
      notes: entry.notes,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    };
  }
}
