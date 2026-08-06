import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { QueryExercisesDto } from './dto/query-exercises.dto';

const detailInclude = {
  category: true,
  muscles: { include: { muscleGroup: true } },
  equipment: { include: { equipmentType: true } },
  alternativesFrom: { include: { alternativeExercise: { include: { category: true } } } },
} satisfies Prisma.ExerciseInclude;

type ExerciseWithRelations = Prisma.ExerciseGetPayload<{ include: typeof detailInclude }>;

@Injectable()
export class ExercisesService {
  constructor(private readonly prisma: PrismaService) {}

  async list(query: QueryExercisesDto) {
    const where: Prisma.ExerciseWhereInput = {
      ...(query.categorySlug ? { category: { slug: query.categorySlug } } : {}),
      ...(query.difficulty ? { difficulty: query.difficulty } : {}),
      ...(query.measurementType ? { measurementType: query.measurementType } : {}),
      ...(query.muscleSlug
        ? { muscles: { some: { muscleGroup: { slug: query.muscleSlug } } } }
        : {}),
      ...(query.equipmentSlug
        ? { equipment: { some: { equipmentType: { slug: query.equipmentSlug } } } }
        : {}),
      ...(query.search
        ? { name: { contains: query.search, mode: Prisma.QueryMode.insensitive } }
        : {}),
    };

    const exercises = await this.prisma.exercise.findMany({
      where,
      include: detailInclude,
      orderBy: { name: 'asc' },
    });

    return exercises.map((exercise) => this.serialize(exercise));
  }

  async getById(id: string) {
    const exercise = await this.prisma.exercise.findUnique({
      where: { id },
      include: detailInclude,
    });

    if (!exercise) {
      throw new NotFoundException('Exercise not found.');
    }

    return this.serialize(exercise);
  }

  /**
   * A simple, deterministic progressive-overload suggestion based on the
   * user's own last completed performance of this exercise — not a
   * personalized AI recommendation. Deliberately does not factor in
   * "recovery": that would require a real recovery/HRV data pipeline from
   * wearables, which this app only simulates today (see
   * packages/docs/wearables.md) — inventing a fake recovery score to react
   * to would be exactly the kind of overclaiming the product explicitly
   * avoids elsewhere.
   */
  async getProgressionSuggestion(userId: string, exerciseId: string) {
    const exercise = await this.prisma.exercise.findUnique({ where: { id: exerciseId } });
    if (!exercise) {
      throw new NotFoundException('Exercise not found.');
    }

    const lastSession = await this.prisma.workoutSession.findFirst({
      where: {
        userId,
        status: 'COMPLETED',
        sets: { some: { exerciseId, isWarmup: false } },
      },
      orderBy: { completedAt: 'desc' },
      include: {
        sets: {
          where: { exerciseId, isWarmup: false },
          orderBy: { setNumber: 'desc' },
          take: 1,
        },
      },
    });

    const lastSet = lastSession?.sets[0];
    if (!lastSet) {
      return { exerciseId, hasPreviousPerformance: false as const };
    }

    return {
      exerciseId,
      hasPreviousPerformance: true as const,
      lastPerformance: {
        performedAt: lastSet.completedAt,
        reps: lastSet.reps,
        weightKg: lastSet.weightKg,
        durationSeconds: lastSet.durationSeconds,
        distanceMeters: lastSet.distanceMeters,
      },
      suggestion: this.suggestNext(lastSet),
    };
  }

  private suggestNext(lastSet: {
    reps: number | null;
    weightKg: number | null;
    durationSeconds: number | null;
    distanceMeters: number | null;
  }) {
    if (lastSet.weightKg !== null) {
      const increment = 2.5;
      const raised = Math.round((lastSet.weightKg * 1.025) / increment) * increment;
      const weightKg = raised > lastSet.weightKg ? raised : lastSet.weightKg + increment;
      return {
        reps: lastSet.reps,
        weightKg,
        durationSeconds: null,
        distanceMeters: null,
        rationale: `Last time: ${lastSet.weightKg} kg × ${lastSet.reps ?? '—'}. Try ${weightKg} kg × ${lastSet.reps ?? '—'} today, or repeat ${lastSet.weightKg} kg if you're not fully recovered.`,
      };
    }

    if (lastSet.durationSeconds !== null) {
      const durationSeconds = Math.max(
        lastSet.durationSeconds + 5,
        Math.round(lastSet.durationSeconds * 1.1),
      );
      return {
        reps: null,
        weightKg: null,
        durationSeconds,
        distanceMeters: null,
        rationale: `Last time: ${lastSet.durationSeconds}s. Try ${durationSeconds}s today, or repeat ${lastSet.durationSeconds}s if you're not fully recovered.`,
      };
    }

    if (lastSet.distanceMeters !== null) {
      const distanceMeters = Math.round(lastSet.distanceMeters * 1.1);
      return {
        reps: null,
        weightKg: null,
        durationSeconds: null,
        distanceMeters,
        rationale: `Last time: ${lastSet.distanceMeters}m. Try ${distanceMeters}m today, or repeat ${lastSet.distanceMeters}m if you're not fully recovered.`,
      };
    }

    if (lastSet.reps !== null) {
      const reps = lastSet.reps + 1;
      return {
        reps,
        weightKg: null,
        durationSeconds: null,
        distanceMeters: null,
        rationale: `Last time: ${lastSet.reps} reps. Try ${reps} reps today, or repeat ${lastSet.reps} if you're not fully recovered.`,
      };
    }

    return null;
  }

  private serialize(exercise: ExerciseWithRelations) {
    return {
      id: exercise.id,
      name: exercise.name,
      slug: exercise.slug,
      description: exercise.description,
      difficulty: exercise.difficulty,
      measurementType: exercise.measurementType,
      instructions: exercise.instructions,
      safetyTips: exercise.safetyTips,
      commonMistakes: exercise.commonMistakes,
      imageUrl: exercise.imageUrl,
      videoUrl: exercise.videoUrl,
      category: exercise.category,
      primaryMuscles: exercise.muscles
        .filter((m) => m.role === 'PRIMARY')
        .map((m) => m.muscleGroup),
      secondaryMuscles: exercise.muscles
        .filter((m) => m.role === 'SECONDARY')
        .map((m) => m.muscleGroup),
      equipment: exercise.equipment.map((e) => e.equipmentType),
      alternatives: exercise.alternativesFrom.map((a) => ({
        id: a.alternativeExercise.id,
        name: a.alternativeExercise.name,
        slug: a.alternativeExercise.slug,
        difficulty: a.alternativeExercise.difficulty,
        category: a.alternativeExercise.category,
      })),
    };
  }
}
