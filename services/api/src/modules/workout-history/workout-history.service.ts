import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, WorkoutSet } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { QueryWorkoutHistoryDto } from './dto/query-workout-history.dto';

const exerciseSummarySelect = { id: true, name: true, slug: true } satisfies Prisma.ExerciseSelect;

const sessionInclude = {
  workoutPlan: { select: { id: true, name: true } },
  sets: { include: { exercise: { select: exerciseSummarySelect } } },
  substitutions: {
    include: {
      originalExercise: { select: exerciseSummarySelect },
      substituteExercise: { select: exerciseSummarySelect },
    },
    orderBy: { createdAt: Prisma.SortOrder.asc },
  },
} satisfies Prisma.WorkoutSessionInclude;

type SessionWithRelations = Prisma.WorkoutSessionGetPayload<{ include: typeof sessionInclude }>;

/**
 * There is no `WorkoutHistory` table (see the note in schema.prisma) —
 * history is this read model over completed `WorkoutSession`/`WorkoutSet`
 * rows, so there's only ever one place session data can drift out of sync.
 */
@Injectable()
export class WorkoutHistoryService {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string, query: QueryWorkoutHistoryDto) {
    const where: Prisma.WorkoutSessionWhereInput = { userId, status: 'COMPLETED' };

    const [sessions, total] = await Promise.all([
      this.prisma.workoutSession.findMany({
        where,
        include: sessionInclude,
        orderBy: { completedAt: 'desc' },
        skip: (query.page - 1) * query.limit,
        take: query.limit,
      }),
      this.prisma.workoutSession.count({ where }),
    ]);

    return {
      data: sessions.map((session) => this.summarize(session)),
      meta: { page: query.page, limit: query.limit, total },
    };
  }

  async getById(userId: string, id: string) {
    const session = await this.prisma.workoutSession.findUnique({
      where: { id },
      include: sessionInclude,
    });

    if (!session || session.userId !== userId || session.status !== 'COMPLETED') {
      throw new NotFoundException('Workout history entry not found.');
    }

    return this.detail(session);
  }

  private summarize(session: SessionWithRelations) {
    const nonWarmup = session.sets.filter((s) => !s.isWarmup);
    const exerciseIds = new Set(nonWarmup.map((s) => s.exerciseId));

    return {
      id: session.id,
      workoutPlan: session.workoutPlan,
      startedAt: session.startedAt,
      completedAt: session.completedAt,
      activeDurationSeconds: session.activeDurationSeconds,
      exerciseCount: exerciseIds.size,
      setCount: nonWarmup.length,
      totalVolumeKg: this.totalVolume(nonWarmup),
    };
  }

  private detail(session: SessionWithRelations) {
    return {
      ...this.summarize(session),
      notes: session.notes,
      difficultyRating: session.difficultyRating,
      sets: session.sets
        .slice()
        .sort((a, b) => a.completedAt.getTime() - b.completedAt.getTime())
        .map((set) => ({
          id: set.id,
          exercise: set.exercise,
          setNumber: set.setNumber,
          reps: set.reps,
          weightKg: set.weightKg,
          durationSeconds: set.durationSeconds,
          distanceMeters: set.distanceMeters,
          rpe: set.rpe,
          isWarmup: set.isWarmup,
          completedAt: set.completedAt,
        })),
      substitutions: session.substitutions.map((s) => ({
        id: s.id,
        originalExercise: s.originalExercise,
        substituteExercise: s.substituteExercise,
        createdAt: s.createdAt,
      })),
    };
  }

  private totalVolume(sets: WorkoutSet[]): number {
    return sets
      .filter((s) => s.reps !== null && s.weightKg !== null)
      .reduce((sum, s) => sum + s.reps! * s.weightKg!, 0);
  }
}
