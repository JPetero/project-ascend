import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateWorkoutPlanDto } from './dto/create-workout-plan.dto';
import { UpdateWorkoutPlanDto } from './dto/update-workout-plan.dto';
import { WorkoutPlanExerciseDto } from './dto/workout-plan-exercise.dto';

const planInclude = {
  workout: { select: { id: true, name: true, slug: true } },
  exercises: {
    orderBy: { order: Prisma.SortOrder.asc },
    include: { exercise: { include: { category: true } } },
  },
} satisfies Prisma.WorkoutPlanInclude;

type WorkoutPlanWithRelations = Prisma.WorkoutPlanGetPayload<{ include: typeof planInclude }>;

@Injectable()
export class WorkoutPlansService {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string) {
    const plans = await this.prisma.workoutPlan.findMany({
      where: { userId },
      include: planInclude,
      orderBy: { createdAt: 'desc' },
    });
    return plans.map((plan) => this.serialize(plan));
  }

  async getById(userId: string, id: string) {
    const plan = await this.findOwned(userId, id);
    return this.serialize(plan);
  }

  async create(userId: string, dto: CreateWorkoutPlanDto) {
    const exerciseRows = dto.workoutId
      ? await this.exercisesFromCatalogWorkout(dto.workoutId)
      : (dto.exercises ?? []);

    const created = await this.prisma.$transaction(async (tx) => {
      const plan = await tx.workoutPlan.create({
        data: { userId, name: dto.name, workoutId: dto.workoutId },
      });
      if (exerciseRows.length > 0) {
        await tx.workoutPlanExercise.createMany({
          data: exerciseRows.map((exercise) => ({ ...exercise, workoutPlanId: plan.id })),
        });
      }
      return plan;
    });

    return this.getById(userId, created.id);
  }

  async update(userId: string, id: string, dto: UpdateWorkoutPlanDto) {
    await this.findOwned(userId, id);

    await this.prisma.$transaction(async (tx) => {
      if (dto.exercises) {
        await tx.workoutPlanExercise.deleteMany({ where: { workoutPlanId: id } });
        if (dto.exercises.length > 0) {
          await tx.workoutPlanExercise.createMany({
            data: dto.exercises.map((exercise) => ({ ...exercise, workoutPlanId: id })),
          });
        }
      }
      await tx.workoutPlan.update({
        where: { id },
        data: { ...(dto.name !== undefined ? { name: dto.name } : {}), updatedAt: new Date() },
      });
    });

    return this.getById(userId, id);
  }

  async remove(userId: string, id: string): Promise<void> {
    await this.findOwned(userId, id);
    await this.prisma.workoutPlan.delete({ where: { id } });
  }

  private async exercisesFromCatalogWorkout(workoutId: string): Promise<WorkoutPlanExerciseDto[]> {
    const workout = await this.prisma.workout.findUnique({
      where: { id: workoutId },
      include: { exercises: true },
    });
    if (!workout) {
      throw new NotFoundException('Workout not found.');
    }

    return workout.exercises.map((we) => ({
      exerciseId: we.exerciseId,
      order: we.order,
      targetSets: we.targetSets,
      targetReps: we.targetReps ?? undefined,
      targetDurationSeconds: we.targetDurationSeconds ?? undefined,
      targetWeightKg: we.targetWeightKg ?? undefined,
      restSeconds: we.restSeconds,
      notes: we.notes ?? undefined,
    }));
  }

  private async findOwned(userId: string, id: string): Promise<WorkoutPlanWithRelations> {
    const plan = await this.prisma.workoutPlan.findUnique({ where: { id }, include: planInclude });
    if (!plan || plan.userId !== userId) {
      throw new NotFoundException('Workout plan not found.');
    }
    return plan;
  }

  private serialize(plan: WorkoutPlanWithRelations) {
    return {
      id: plan.id,
      name: plan.name,
      workout: plan.workout,
      createdAt: plan.createdAt,
      updatedAt: plan.updatedAt,
      exercises: plan.exercises.map((pe) => ({
        id: pe.id,
        order: pe.order,
        targetSets: pe.targetSets,
        targetReps: pe.targetReps,
        targetDurationSeconds: pe.targetDurationSeconds,
        targetWeightKg: pe.targetWeightKg,
        restSeconds: pe.restSeconds,
        notes: pe.notes,
        exercise: {
          id: pe.exercise.id,
          name: pe.exercise.name,
          slug: pe.exercise.slug,
          difficulty: pe.exercise.difficulty,
          category: pe.exercise.category,
        },
      })),
    };
  }
}
