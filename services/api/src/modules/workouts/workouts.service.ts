import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { QueryWorkoutsDto } from './dto/query-workouts.dto';

const detailInclude = {
  category: true,
  exercises: {
    orderBy: { order: Prisma.SortOrder.asc },
    include: { exercise: { include: { category: true } } },
  },
} satisfies Prisma.WorkoutInclude;

type WorkoutWithRelations = Prisma.WorkoutGetPayload<{ include: typeof detailInclude }>;

@Injectable()
export class WorkoutsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(query: QueryWorkoutsDto) {
    const where: Prisma.WorkoutWhereInput = {
      ...(query.categorySlug ? { category: { slug: query.categorySlug } } : {}),
      ...(query.difficulty ? { difficulty: query.difficulty } : {}),
    };

    const workouts = await this.prisma.workout.findMany({
      where,
      include: detailInclude,
      orderBy: { name: 'asc' },
    });

    return workouts.map((workout) => this.serialize(workout));
  }

  async getById(id: string) {
    const workout = await this.prisma.workout.findUnique({
      where: { id },
      include: detailInclude,
    });

    if (!workout) {
      throw new NotFoundException('Workout not found.');
    }

    return this.serialize(workout);
  }

  private serialize(workout: WorkoutWithRelations) {
    return {
      id: workout.id,
      name: workout.name,
      slug: workout.slug,
      description: workout.description,
      difficulty: workout.difficulty,
      estimatedDurationMinutes: workout.estimatedDurationMinutes,
      category: workout.category,
      exercises: workout.exercises.map((we) => ({
        id: we.id,
        order: we.order,
        targetSets: we.targetSets,
        targetReps: we.targetReps,
        targetDurationSeconds: we.targetDurationSeconds,
        targetWeightKg: we.targetWeightKg,
        restSeconds: we.restSeconds,
        notes: we.notes,
        exercise: {
          id: we.exercise.id,
          name: we.exercise.name,
          slug: we.exercise.slug,
          difficulty: we.exercise.difficulty,
          category: we.exercise.category,
        },
      })),
    };
  }
}
