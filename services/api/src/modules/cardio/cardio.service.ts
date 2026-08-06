import { Injectable, NotFoundException } from '@nestjs/common';
import { CardioSession, Prisma, CardioSessionSource } from '@prisma/client';
import { IdempotencyService } from '../../common/idempotency/idempotency.service';
import { encodePolyline, trimEndpoints } from '../../common/geo/polyline.util';
import { PrismaService } from '../../prisma/prisma.service';
import { AchievementsService } from '../achievements/achievements.service';
import { CreateCardioSessionDto } from './dto/create-cardio-session.dto';
import { QueryCardioSessionsDto } from './dto/query-cardio-sessions.dto';
import { UpdateCardioSessionDto } from './dto/update-cardio-session.dto';

/**
 * Manual/summary and LIVE_GPS cardio logging — see schema.prisma's
 * CardioSession comment and
 * packages/docs/product/user-scenario-bible.md Scenario 12. Wearable
 * ingestion (source: WEARABLE) is future work (see the Health Connect/
 * HealthKit foundation); this module already has the field ready for it.
 */
@Injectable()
export class CardioService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly idempotencyService: IdempotencyService,
    private readonly achievementsService: AchievementsService,
  ) {}

  /**
   * Returns a full `{ data, meta, error }` envelope — `data` stays exactly
   * the serialized session, `meta.newAchievements` additively carries any
   * achievement newly earned by this cardio session finishing. See the
   * matching comment on `NutritionLogService.addEntry`.
   */
  async create(userId: string, dto: CreateCardioSessionDto) {
    const run = async () => {
      const hideRoute = dto.hideRoute ?? true;
      // Route points are only ever persisted for a session whose owner
      // did not ask to hide the route — trimmed/discarded points never
      // reach storage in the first place (see trimEndpoints and its own
      // doc comment), which is a stronger privacy guarantee than merely
      // filtering them out of API responses after the fact.
      let encodedRoute: string | null = null;
      let routePointCount: number | null = null;
      if (!hideRoute && dto.routePoints && dto.routePoints.length > 0) {
        const trimmed = trimEndpoints(dto.routePoints, {
          trimStart: dto.hideStartLocation ?? true,
          trimEnd: dto.hideEndLocation ?? true,
        });
        if (trimmed.length > 0) {
          encodedRoute = encodePolyline(trimmed);
          routePointCount = trimmed.length;
        }
      }

      const created = await this.prisma.cardioSession.create({
        data: {
          userId,
          activityType: dto.activityType,
          source: dto.source ?? CardioSessionSource.MANUAL,
          startedAt: new Date(dto.startedAt),
          durationSeconds: dto.durationSeconds,
          distanceMeters: dto.distanceMeters,
          elevationGainMeters: dto.elevationGainMeters,
          estimatedCalories: dto.estimatedCalories,
          regionLabel: dto.regionLabel,
          hideRoute,
          hideStartLocation: dto.hideStartLocation ?? true,
          hideEndLocation: dto.hideEndLocation ?? true,
          encodedRoute,
          routePointCount,
          notes: dto.notes,
        },
      });

      const newAchievements = await this.achievementsService.evaluateCardioAchievements(userId);

      return {
        entityId: created.id,
        payload: { session: this.serialize(created), newAchievements },
      };
    };

    const result = dto.idempotencyKey
      ? await this.idempotencyService.run(
          {
            userId,
            idempotencyKey: dto.idempotencyKey,
            entityType: 'CARDIO_SESSION',
            operationType: 'CREATE',
          },
          run,
        )
      : (await run()).payload;

    return { data: result.session, meta: { newAchievements: result.newAchievements }, error: null };
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
        // Opting into hideRoute after the fact permanently discards the
        // stored route rather than merely hiding it — there is no
        // "un-hide" that brings the coordinates back, which is the
        // stronger, more honest privacy guarantee (see
        // wellness-ethics-bible.md's location-privacy rule).
        ...(dto.hideRoute === true ? { encodedRoute: null, routePointCount: null } : {}),
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
      source: session.source,
      startedAt: session.startedAt,
      durationSeconds: session.durationSeconds,
      distanceMeters: session.distanceMeters,
      elevationGainMeters: session.elevationGainMeters,
      estimatedCalories: session.estimatedCalories,
      regionLabel: session.regionLabel,
      hideRoute: session.hideRoute,
      hideStartLocation: session.hideStartLocation,
      hideEndLocation: session.hideEndLocation,
      // hasRoute tells the client whether a route exists at all, without
      // ever exposing coordinates when hideRoute is set — the encoded
      // route itself is only ever included in the response below when
      // the owner hasn't asked to hide it.
      hasRoute: session.encodedRoute != null,
      ...(session.hideRoute
        ? {}
        : {
            encodedRoute: session.encodedRoute,
            routePointCount: session.routePointCount,
          }),
      notes: session.notes,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    };
  }
}
