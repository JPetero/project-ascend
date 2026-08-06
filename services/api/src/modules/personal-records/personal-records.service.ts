import { Injectable } from '@nestjs/common';
import { PersonalRecordType, WorkoutSet } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

interface PersonalRecordCandidate {
  type: PersonalRecordType;
  value: number;
  unit: string;
}

@Injectable()
export class PersonalRecordsService {
  constructor(private readonly prisma: PrismaService) {}

  list(userId: string) {
    return this.prisma.personalRecord.findMany({
      where: { userId },
      include: { exercise: { select: { id: true, name: true, slug: true } } },
      orderBy: { achievedAt: 'desc' },
    });
  }

  /**
   * Computes each candidate personal-record value (max weight/reps/
   * duration/distance/volume) for every exercise logged in this session,
   * and upserts any that beat the user's current best — or set a
   * first-ever record for that exercise+type. Returns only the ones that
   * were newly set or broken, so the caller (WorkoutSessionsService, right
   * after marking a session COMPLETED) can surface a "new PR!" moment.
   *
   * "Volume" here means total work for an exercise within this session
   * (sum of reps × weight across its sets) — the standard strength-
   * training definition, not workout duration.
   */
  async detectAndRecord(userId: string, workoutSessionId: string) {
    const sets = await this.prisma.workoutSet.findMany({
      where: { workoutSessionId, isWarmup: false },
    });

    const setsByExercise = new Map<string, WorkoutSet[]>();
    for (const set of sets) {
      const existing = setsByExercise.get(set.exerciseId);
      if (existing) {
        existing.push(set);
      } else {
        setsByExercise.set(set.exerciseId, [set]);
      }
    }

    const broken = [];
    for (const [exerciseId, exerciseSets] of setsByExercise) {
      for (const candidate of this.computeCandidates(exerciseSets)) {
        const result = await this.upsertIfBetter(userId, exerciseId, workoutSessionId, candidate);
        if (result) {
          broken.push(result);
        }
      }
    }

    return broken;
  }

  private computeCandidates(sets: WorkoutSet[]): PersonalRecordCandidate[] {
    const candidates: PersonalRecordCandidate[] = [];

    const weights = sets.map((s) => s.weightKg).filter((v): v is number => v !== null);
    if (weights.length > 0) {
      candidates.push({
        type: PersonalRecordType.MAX_WEIGHT,
        value: Math.max(...weights),
        unit: 'kg',
      });
    }

    const reps = sets.map((s) => s.reps).filter((v): v is number => v !== null);
    if (reps.length > 0) {
      candidates.push({
        type: PersonalRecordType.MAX_REPS,
        value: Math.max(...reps),
        unit: 'reps',
      });
    }

    const durations = sets.map((s) => s.durationSeconds).filter((v): v is number => v !== null);
    if (durations.length > 0) {
      candidates.push({
        type: PersonalRecordType.MAX_DURATION,
        value: Math.max(...durations),
        unit: 's',
      });
    }

    const distances = sets.map((s) => s.distanceMeters).filter((v): v is number => v !== null);
    if (distances.length > 0) {
      candidates.push({
        type: PersonalRecordType.MAX_DISTANCE,
        value: Math.max(...distances),
        unit: 'm',
      });
    }

    const weightedSets = sets.filter(
      (s): s is WorkoutSet & { reps: number; weightKg: number } =>
        s.reps !== null && s.weightKg !== null,
    );
    if (weightedSets.length > 0) {
      const volume = weightedSets.reduce((sum, s) => sum + s.reps * s.weightKg, 0);
      candidates.push({ type: PersonalRecordType.MAX_VOLUME, value: volume, unit: 'kg' });
    }

    return candidates;
  }

  private async upsertIfBetter(
    userId: string,
    exerciseId: string,
    workoutSessionId: string,
    candidate: PersonalRecordCandidate,
  ) {
    const existing = await this.prisma.personalRecord.findUnique({
      where: { userId_exerciseId_type: { userId, exerciseId, type: candidate.type } },
    });

    if (existing && existing.value >= candidate.value) {
      return null;
    }

    const record = await this.prisma.personalRecord.upsert({
      where: { userId_exerciseId_type: { userId, exerciseId, type: candidate.type } },
      create: {
        userId,
        exerciseId,
        type: candidate.type,
        value: candidate.value,
        unit: candidate.unit,
        workoutSessionId,
      },
      update: {
        value: candidate.value,
        unit: candidate.unit,
        workoutSessionId,
        achievedAt: new Date(),
      },
      include: { exercise: { select: { id: true, name: true, slug: true } } },
    });

    return { ...record, previousValue: existing?.value ?? null, isFirstRecord: !existing };
  }
}
