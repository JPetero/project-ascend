import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { AuditService } from '../../common/audit/audit.service';
import { PrismaService } from '../../prisma/prisma.service';
import { PersonalRecordsService } from '../personal-records/personal-records.service';
import { LogSetDto } from './dto/log-set.dto';
import { StartWorkoutSessionDto } from './dto/start-workout-session.dto';
import { UpdateSetDto } from './dto/update-set.dto';

const sessionInclude = {
  workoutPlan: { select: { id: true, name: true } },
  sets: {
    include: { exercise: { select: { id: true, name: true, slug: true } } },
    orderBy: { completedAt: Prisma.SortOrder.asc },
  },
} satisfies Prisma.WorkoutSessionInclude;

type SessionWithRelations = Prisma.WorkoutSessionGetPayload<{ include: typeof sessionInclude }>;

const ACTIVE_STATUSES = ['IN_PROGRESS', 'PAUSED'] as const;

@Injectable()
export class WorkoutSessionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly personalRecordsService: PersonalRecordsService,
    private readonly auditService: AuditService,
  ) {}

  async start(userId: string, dto: StartWorkoutSessionDto) {
    const active = await this.prisma.workoutSession.findFirst({
      where: { userId, status: { in: [...ACTIVE_STATUSES] } },
    });
    if (active) {
      throw new ConflictException(
        'You already have a workout session in progress. Finish or abandon it before starting another.',
      );
    }

    if (dto.workoutPlanId) {
      const plan = await this.prisma.workoutPlan.findUnique({ where: { id: dto.workoutPlanId } });
      if (!plan || plan.userId !== userId) {
        throw new NotFoundException('Workout plan not found.');
      }
    }

    const session = await this.prisma.workoutSession.create({
      data: { userId, workoutPlanId: dto.workoutPlanId },
    });

    return this.getById(userId, session.id);
  }

  async getActive(userId: string) {
    const session = await this.prisma.workoutSession.findFirst({
      where: { userId, status: { in: [...ACTIVE_STATUSES] } },
      include: sessionInclude,
    });
    return session ? this.serialize(session) : null;
  }

  async getById(userId: string, id: string) {
    return this.serialize(await this.findOwned(userId, id));
  }

  async pause(userId: string, id: string) {
    const session = await this.findOwned(userId, id);
    if (session.status !== 'IN_PROGRESS') {
      throw new ConflictException('Only an in-progress session can be paused.');
    }

    const now = new Date();
    await this.prisma.workoutSession.update({
      where: { id },
      data: {
        status: 'PAUSED',
        pausedAt: now,
        activeDurationSeconds:
          session.activeDurationSeconds + this.secondsSince(session.resumedAt, now),
      },
    });

    return this.getById(userId, id);
  }

  async resume(userId: string, id: string) {
    const session = await this.findOwned(userId, id);
    if (session.status !== 'PAUSED') {
      throw new ConflictException('Only a paused session can be resumed.');
    }

    await this.prisma.workoutSession.update({
      where: { id },
      data: { status: 'IN_PROGRESS', resumedAt: new Date(), pausedAt: null },
    });

    return this.getById(userId, id);
  }

  async finish(userId: string, id: string) {
    const session = await this.endSession(userId, id, 'COMPLETED');

    const newPersonalRecords = await this.personalRecordsService.detectAndRecord(userId, id);
    await this.auditService.record({
      userId,
      action: 'workout.session_completed',
      entityType: 'WorkoutSession',
      entityId: id,
    });

    return { session: this.serialize(session), newPersonalRecords };
  }

  async abandon(userId: string, id: string) {
    const session = await this.endSession(userId, id, 'ABANDONED');
    return this.serialize(session);
  }

  async logSet(userId: string, sessionId: string, dto: LogSetDto) {
    const session = await this.findOwned(userId, sessionId);
    if (session.status !== 'IN_PROGRESS') {
      throw new ConflictException('Sets can only be logged while a session is in progress.');
    }

    const exercise = await this.prisma.exercise.findUnique({ where: { id: dto.exerciseId } });
    if (!exercise) {
      throw new NotFoundException('Exercise not found.');
    }

    return this.prisma.$transaction(async (tx) => {
      const lastSet = await tx.workoutSet.findFirst({
        where: { workoutSessionId: sessionId, exerciseId: dto.exerciseId },
        orderBy: { setNumber: 'desc' },
      });

      return tx.workoutSet.create({
        data: {
          workoutSessionId: sessionId,
          exerciseId: dto.exerciseId,
          setNumber: (lastSet?.setNumber ?? 0) + 1,
          reps: dto.reps,
          weightKg: dto.weightKg,
          durationSeconds: dto.durationSeconds,
          distanceMeters: dto.distanceMeters,
          isWarmup: dto.isWarmup ?? false,
        },
        include: { exercise: { select: { id: true, name: true, slug: true } } },
      });
    });
  }

  async updateSet(userId: string, sessionId: string, setId: string, dto: UpdateSetDto) {
    await this.findOwnedSet(userId, sessionId, setId);

    return this.prisma.workoutSet.update({
      where: { id: setId },
      data: {
        ...(dto.reps !== undefined ? { reps: dto.reps } : {}),
        ...(dto.weightKg !== undefined ? { weightKg: dto.weightKg } : {}),
        ...(dto.durationSeconds !== undefined ? { durationSeconds: dto.durationSeconds } : {}),
        ...(dto.distanceMeters !== undefined ? { distanceMeters: dto.distanceMeters } : {}),
        ...(dto.isWarmup !== undefined ? { isWarmup: dto.isWarmup } : {}),
      },
      include: { exercise: { select: { id: true, name: true, slug: true } } },
    });
  }

  async removeSet(userId: string, sessionId: string, setId: string): Promise<void> {
    await this.findOwnedSet(userId, sessionId, setId);
    await this.prisma.workoutSet.delete({ where: { id: setId } });
  }

  private async endSession(
    userId: string,
    id: string,
    status: 'COMPLETED' | 'ABANDONED',
  ): Promise<SessionWithRelations> {
    const session = await this.findOwned(userId, id);
    if (session.status !== 'IN_PROGRESS' && session.status !== 'PAUSED') {
      throw new ConflictException('This session has already ended.');
    }

    const now = new Date();
    const additionalSeconds =
      session.status === 'IN_PROGRESS' ? this.secondsSince(session.resumedAt, now) : 0;

    await this.prisma.workoutSession.update({
      where: { id },
      data: {
        status,
        completedAt: now,
        activeDurationSeconds: session.activeDurationSeconds + additionalSeconds,
      },
    });

    return this.findOwned(userId, id);
  }

  private secondsSince(start: Date, end: Date): number {
    return Math.max(0, Math.floor((end.getTime() - start.getTime()) / 1000));
  }

  private async findOwned(userId: string, id: string): Promise<SessionWithRelations> {
    const session = await this.prisma.workoutSession.findUnique({
      where: { id },
      include: sessionInclude,
    });
    if (!session || session.userId !== userId) {
      throw new NotFoundException('Workout session not found.');
    }
    return session;
  }

  private async findOwnedSet(userId: string, sessionId: string, setId: string) {
    await this.findOwned(userId, sessionId);
    const set = await this.prisma.workoutSet.findUnique({ where: { id: setId } });
    if (!set || set.workoutSessionId !== sessionId) {
      throw new NotFoundException('Set not found.');
    }
    return set;
  }

  private serialize(session: SessionWithRelations) {
    return {
      id: session.id,
      status: session.status,
      workoutPlan: session.workoutPlan,
      startedAt: session.startedAt,
      resumedAt: session.resumedAt,
      pausedAt: session.pausedAt,
      completedAt: session.completedAt,
      activeDurationSeconds: session.activeDurationSeconds,
      notes: session.notes,
      sets: session.sets.map((set) => ({
        id: set.id,
        exercise: set.exercise,
        setNumber: set.setNumber,
        reps: set.reps,
        weightKg: set.weightKg,
        durationSeconds: set.durationSeconds,
        distanceMeters: set.distanceMeters,
        isWarmup: set.isWarmup,
        completedAt: set.completedAt,
      })),
    };
  }
}
