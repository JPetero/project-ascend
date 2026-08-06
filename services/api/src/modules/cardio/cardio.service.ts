import { Injectable, NotFoundException } from '@nestjs/common';
import { CardioSession, Prisma } from '@prisma/client';
import { IdempotencyService } from '../../common/idempotency/idempotency.service';
import { PrismaService } from '../../prisma/prisma.service';
import { AchievementsService } from '../achievements/achievements.service';
import { CreateCardioSessionDto } from './dto/create-cardio-session.dto';
import { QueryCardioSessionsDto } from './dto/query-cardio-sessions.dto';
import { UpdateCardioSessionDto } from './dto/update-cardio-session.dto';

/**
 * Manual/summary GPS Cardio logging — see schema.prisma's CardioSession
 * comment and packages/docs/product/user-scenario-bible.md Scenario 12.
 * Route recording, live tracking, and wearable ingestion are future work;
 * this is the record-keeping and privacy-flag foundation they'll build on.
 */
@Injectable()
export class CardioService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly idempotencyService: IdempotencyService,
    private readonly achievementsService: AchievementsService,
  ) {}

  async create(userId: string, dto: CreateCardioSessionDto) {
    const run = async () => {
      const created = await this.prisma.cardioSession.create({
        data: {
          userId,
          activityType: dto.activityType,
          startedAt: new Date(dto.startedAt),
          durationSeconds: dto.durationSeconds,
          distanceMeters: dto.distanceMeters,
          elevationGainMeters: dto.elevationGainMeters,
          estimatedCalories: dto.estimatedCalories,
          regionLabel: dto.regionLabel,
          hideRoute: dto.hideRoute ?? true,
          hideStartLocation: dto.hideStartLocation ?? true,
          hideEndLocation: dto.hideEndLocation ?? true,
          notes: dto.notes,
        },
      });

      // Result intentionally not surfaced in this response — see the same
      // decision documented on NutritionLogService.createEntry(). The
      // idempotent upsert makes calling this on every log always safe.
      await this.achievementsService.evaluateCardioAchievements(userId);

      return { entityId: created.id, payload: this.serialize(created) };
    };

    if (dto.idempotencyKey) {
      return this.idempotencyService.run(
        {
          userId,
          idempotencyKey: dto.idempotencyKey,
          entityType: 'CARDIO_SESSION',
          operationType: 'CREATE',
        },
        run,
      );
    }
    return (await run()).payload;
  }

  async list(userId: string, query: QueryCardioSessionsDto) {
    const where: Prisma.CardioSessionWhereInput = { userId };

    const [sessions, total] = await Promise.all([
      this.prisma.cardioSession.findMany({
        where,
        orderBy: { startedAt: 'desc' },
        skip: (query.page - 1) * query.limit,
        take: query.limit,
      }),
      this.prisma.cardioSession.count({ where }),
    ]);

    return {
      data: sessions.map((session) => this.serialize(session)),
      meta: { page: query.page, limit: query.limit, total },
    };
  }

  async getById(userId: string, id: string) {
    return this.serialize(await this.findOwned(userId, id));
  }

  async update(userId: string, id: string, dto: UpdateCardioSessionDto) {
    await this.findOwned(userId, id);
    const updated = await this.prisma.cardioSession.update({
      where: { id },
      data: {
        ...(dto.hideRoute !== undefined ? { hideRoute: dto.hideRoute } : {}),
        ...(dto.hideStartLocation !== undefined
          ? { hideStartLocation: dto.hideStartLocation }
          : {}),
        ...(dto.hideEndLocation !== undefined ? { hideEndLocation: dto.hideEndLocation } : {}),
        ...(dto.notes !== undefined ? { notes: dto.notes } : {}),
      },
    });
    return this.serialize(updated);
  }

  async delete(userId: string, id: string): Promise<void> {
    await this.findOwned(userId, id);
    await this.prisma.cardioSession.delete({ where: { id } });
  }

  private async findOwned(userId: string, id: string): Promise<CardioSession> {
    const session = await this.prisma.cardioSession.findUnique({ where: { id } });
    if (!session || session.userId !== userId) {
      throw new NotFoundException('Cardio session not found.');
    }
    return session;
  }

  private serialize(session: CardioSession) {
    return {
      id: session.id,
      activityType: session.activityType,
      startedAt: session.startedAt,
      durationSeconds: session.durationSeconds,
      distanceMeters: session.distanceMeters,
      elevationGainMeters: session.elevationGainMeters,
      estimatedCalories: session.estimatedCalories,
      regionLabel: session.regionLabel,
      hideRoute: session.hideRoute,
      hideStartLocation: session.hideStartLocation,
      hideEndLocation: session.hideEndLocation,
      notes: session.notes,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    };
  }
}
