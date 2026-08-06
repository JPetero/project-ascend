import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { FoodSourceType, Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateFoodDto } from './dto/create-food.dto';
import { QueryFoodsDto } from './dto/query-foods.dto';
import { UpdateFoodDto } from './dto/update-food.dto';

const foodInclude = { servings: true } satisfies Prisma.FoodInclude;
type FoodWithRelations = Prisma.FoodGetPayload<{ include: typeof foodInclude }>;

@Injectable()
export class FoodsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * A user's search always sees the shared seed library plus *their own*
   * custom foods — never another user's. Archived foods are hidden by
   * default (they still exist for already-logged `MealEntry` rows, which
   * keep their own macro snapshot regardless).
   */
  async search(userId: string, query: QueryFoodsDto) {
    // Visibility (seed catalog + this user's own custom foods) and the
    // optional text search are two independent OR clauses — combined via
    // an explicit `AND` array, since a second top-level `OR` key would
    // just overwrite the first rather than being combined with it.
    const visibility: Prisma.FoodWhereInput = {
      OR: [{ sourceType: FoodSourceType.SEED }, { ownerId: userId }],
    };
    const textSearch: Prisma.FoodWhereInput | undefined = query.search
      ? {
          OR: [
            { name: { contains: query.search, mode: Prisma.QueryMode.insensitive } },
            { alternateName: { contains: query.search, mode: Prisma.QueryMode.insensitive } },
            { brand: { contains: query.search, mode: Prisma.QueryMode.insensitive } },
          ],
        }
      : undefined;

    const where: Prisma.FoodWhereInput = {
      archivedAt: null,
      AND: textSearch ? [visibility, textSearch] : [visibility],
    };

    const [foods, total] = await Promise.all([
      this.prisma.food.findMany({
        where,
        include: foodInclude,
        orderBy: { name: 'asc' },
        skip: (query.page - 1) * query.limit,
        take: query.limit,
      }),
      this.prisma.food.count({ where }),
    ]);

    return {
      data: foods.map((food) => this.serialize(food)),
      meta: { page: query.page, limit: query.limit, total },
    };
  }

  async getById(userId: string, id: string) {
    const food = await this.findVisible(userId, id);
    return this.serialize(food);
  }

  async createCustom(userId: string, dto: CreateFoodDto) {
    const food = await this.prisma.$transaction(async (tx) => {
      const created = await tx.food.create({
        data: {
          name: dto.name,
          alternateName: dto.alternateName,
          brand: dto.brand,
          sourceType: FoodSourceType.USER,
          ownerId: userId,
          servingDescription: dto.servingDescription,
          servingGrams: dto.servingGrams,
          caloriesPerServing: dto.caloriesPerServing,
          proteinGramsPerServing: dto.proteinGramsPerServing,
          carbGramsPerServing: dto.carbGramsPerServing,
          fatGramsPerServing: dto.fatGramsPerServing,
          fiberGramsPerServing: dto.fiberGramsPerServing,
          sodiumMgPerServing: dto.sodiumMgPerServing,
          isEstimated: dto.isEstimated ?? true,
        },
      });

      if (dto.servings && dto.servings.length > 0) {
        await tx.foodServing.createMany({
          data: dto.servings.map((serving) => ({ ...serving, foodId: created.id })),
        });
      }

      return created;
    });

    return this.getById(userId, food.id);
  }

  async updateCustom(userId: string, id: string, dto: UpdateFoodDto) {
    await this.findOwnedCustom(userId, id);

    await this.prisma.$transaction(async (tx) => {
      if (dto.servings) {
        await tx.foodServing.deleteMany({ where: { foodId: id } });
        if (dto.servings.length > 0) {
          await tx.foodServing.createMany({
            data: dto.servings.map((serving) => ({ ...serving, foodId: id })),
          });
        }
      }

      await tx.food.update({
        where: { id },
        data: {
          ...(dto.name !== undefined ? { name: dto.name } : {}),
          ...(dto.alternateName !== undefined ? { alternateName: dto.alternateName } : {}),
          ...(dto.brand !== undefined ? { brand: dto.brand } : {}),
          ...(dto.servingDescription !== undefined
            ? { servingDescription: dto.servingDescription }
            : {}),
          ...(dto.servingGrams !== undefined ? { servingGrams: dto.servingGrams } : {}),
          ...(dto.caloriesPerServing !== undefined
            ? { caloriesPerServing: dto.caloriesPerServing }
            : {}),
          ...(dto.proteinGramsPerServing !== undefined
            ? { proteinGramsPerServing: dto.proteinGramsPerServing }
            : {}),
          ...(dto.carbGramsPerServing !== undefined
            ? { carbGramsPerServing: dto.carbGramsPerServing }
            : {}),
          ...(dto.fatGramsPerServing !== undefined
            ? { fatGramsPerServing: dto.fatGramsPerServing }
            : {}),
          ...(dto.fiberGramsPerServing !== undefined
            ? { fiberGramsPerServing: dto.fiberGramsPerServing }
            : {}),
          ...(dto.sodiumMgPerServing !== undefined
            ? { sodiumMgPerServing: dto.sodiumMgPerServing }
            : {}),
          ...(dto.isEstimated !== undefined ? { isEstimated: dto.isEstimated } : {}),
        },
      });
    });

    return this.getById(userId, id);
  }

  async archiveCustom(userId: string, id: string) {
    await this.findOwnedCustom(userId, id);
    await this.prisma.food.update({ where: { id }, data: { archivedAt: new Date() } });
    return this.getById(userId, id);
  }

  private async findVisible(userId: string, id: string): Promise<FoodWithRelations> {
    const food = await this.prisma.food.findUnique({ where: { id }, include: foodInclude });
    if (!food || (food.sourceType === FoodSourceType.USER && food.ownerId !== userId)) {
      throw new NotFoundException('Food not found.');
    }
    return food;
  }

  private async findOwnedCustom(userId: string, id: string): Promise<FoodWithRelations> {
    const food = await this.findVisible(userId, id);
    if (food.sourceType !== FoodSourceType.USER || food.ownerId !== userId) {
      throw new ForbiddenException('Only your own custom foods can be edited or archived.');
    }
    return food;
  }

  private serialize(food: FoodWithRelations) {
    return {
      id: food.id,
      name: food.name,
      alternateName: food.alternateName,
      brand: food.brand,
      sourceType: food.sourceType,
      isOwnedByCurrentUser: food.sourceType === FoodSourceType.USER,
      servingDescription: food.servingDescription,
      servingGrams: food.servingGrams,
      caloriesPerServing: food.caloriesPerServing,
      proteinGramsPerServing: food.proteinGramsPerServing,
      carbGramsPerServing: food.carbGramsPerServing,
      fatGramsPerServing: food.fatGramsPerServing,
      fiberGramsPerServing: food.fiberGramsPerServing,
      sodiumMgPerServing: food.sodiumMgPerServing,
      isEstimated: food.isEstimated,
      archivedAt: food.archivedAt,
      servings: food.servings.map((s) => ({
        id: s.id,
        label: s.label,
        grams: s.grams,
        isDefault: s.isDefault,
      })),
    };
  }
}
