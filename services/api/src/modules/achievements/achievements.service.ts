import { Injectable } from '@nestjs/common';
import { Achievement } from '@prisma/client';
import { calculateStreak } from '../../common/progress/progress.util';
import { PrismaService } from '../../prisma/prisma.service';

interface AchievementContext {
  completedWorkoutCount: number;
  currentWorkoutStreakDays: number;
  personalRecordCount: number;
  mealsLoggedCount: number;
  cardioSessionCount: number;
}

interface AchievementRule {
  key: string;
  progress: (context: AchievementContext) => number;
}

/**
 * Every achievement this build can award, keyed to the seeded `Achievement`
 * catalog rows (see prisma/seed.ts's `seedAchievements`). `RECOVERY` has no
 * rules yet — deload doesn't have a countable "did this" trigger the way
 * workout/nutrition/cardio logging do.
 */
const WORKOUT_RULES: AchievementRule[] = [
  { key: 'first_workout', progress: (c) => c.completedWorkoutCount },
  { key: 'ten_workouts', progress: (c) => c.completedWorkoutCount },
  { key: 'fifty_workouts', progress: (c) => c.completedWorkoutCount },
  { key: 'first_personal_record', progress: (c) => c.personalRecordCount },
  { key: 'seven_day_streak', progress: (c) => c.currentWorkoutStreakDays },
  { key: 'thirty_day_streak', progress: (c) => c.currentWorkoutStreakDays },
];

const NUTRITION_RULES: AchievementRule[] = [
  { key: 'first_meal_logged', progress: (c) => c.mealsLoggedCount },
  { key: 'hundred_meals_logged', progress: (c) => c.mealsLoggedCount },
];

const CARDIO_RULES: AchievementRule[] = [
  { key: 'first_cardio_session', progress: (c) => c.cardioSessionCount },
  { key: 'ten_cardio_sessions', progress: (c) => c.cardioSessionCount },
];

const EMPTY_CONTEXT: AchievementContext = {
  completedWorkoutCount: 0,
  currentWorkoutStreakDays: 0,
  personalRecordCount: 0,
  mealsLoggedCount: 0,
  cardioSessionCount: 0,
};

@Injectable()
export class AchievementsService {
  constructor(private readonly prisma: PrismaService) {}

  /** The full catalog with this user's progress merged in — 0 progress and
   * a null `earnedAt` for anything never triggered yet, so the Flutter
   * screen can render every achievement (including locked ones) without a
   * second "what exists" query. */
  async listForUser(userId: string) {
    const [achievements, awards] = await Promise.all([
      this.prisma.achievement.findMany({ orderBy: [{ category: 'asc' }, { targetSteps: 'asc' }] }),
      this.prisma.achievementAward.findMany({ where: { userId } }),
    ]);
    const awardByAchievementId = new Map(awards.map((award) => [award.achievementId, award]));

    return achievements.map((achievement) => {
      const award = awardByAchievementId.get(achievement.id);
      return {
        id: achievement.id,
        key: achievement.key,
        title: achievement.title,
        description: achievement.description,
        iconAsset: achievement.iconAsset,
        category: achievement.category,
        targetSteps: achievement.targetSteps,
        progress: award?.progress ?? 0,
        earnedAt: award?.earnedAt ?? null,
      };
    });
  }

  /**
   * Recomputes workout/streak/personal-record achievement progress for
   * `userId` and idempotently upserts `AchievementAward` rows — safe to
   * call after every workout completion, however many times. Returns only
   * the achievements newly earned in *this* call, so the caller (right
   * after `WorkoutSessionsService.finish()`) can surface a celebration
   * moment without re-celebrating something already earned.
   */
  async evaluateWorkoutAchievements(userId: string) {
    const [completedWorkoutCount, completedSessions, personalRecordCount] = await Promise.all([
      this.prisma.workoutSession.count({ where: { userId, status: 'COMPLETED' } }),
      this.prisma.workoutSession.findMany({
        where: { userId, status: 'COMPLETED' },
        select: { completedAt: true },
      }),
      this.prisma.personalRecord.count({ where: { userId } }),
    ]);

    const currentWorkoutStreakDays = calculateStreak(
      completedSessions.map((s) => s.completedAt).filter((d): d is Date => d !== null),
    );

    return this.evaluate(userId, WORKOUT_RULES, {
      ...EMPTY_CONTEXT,
      completedWorkoutCount,
      currentWorkoutStreakDays,
      personalRecordCount,
    });
  }

  /** Same idempotent pattern as {@link evaluateWorkoutAchievements}, for
   * the nutrition-logging achievements — safe to call after every logged
   * meal. */
  async evaluateNutritionAchievements(userId: string) {
    const mealsLoggedCount = await this.prisma.mealEntry.count({ where: { userId } });

    return this.evaluate(userId, NUTRITION_RULES, { ...EMPTY_CONTEXT, mealsLoggedCount });
  }

  /** Same idempotent pattern as {@link evaluateWorkoutAchievements}, for
   * the GPS Cardio achievements — safe to call after every logged cardio
   * session. */
  async evaluateCardioAchievements(userId: string) {
    const cardioSessionCount = await this.prisma.cardioSession.count({ where: { userId } });

    return this.evaluate(userId, CARDIO_RULES, { ...EMPTY_CONTEXT, cardioSessionCount });
  }

  private async evaluate(userId: string, rules: AchievementRule[], context: AchievementContext) {
    const achievements = await this.prisma.achievement.findMany({
      where: { key: { in: rules.map((rule) => rule.key) } },
    });
    const existingAwards = await this.prisma.achievementAward.findMany({
      where: { userId, achievementId: { in: achievements.map((a) => a.id) } },
    });
    const existingByAchievementId = new Map(
      existingAwards.map((award) => [award.achievementId, award]),
    );

    const newlyEarned = [];
    for (const achievement of achievements) {
      const existing = existingByAchievementId.get(achievement.id);
      if (existing?.earnedAt) continue;

      const rule = rules.find((r) => r.key === achievement.key);
      if (!rule) continue;

      const progress = Math.min(rule.progress(context), achievement.targetSteps);
      const earned = progress >= achievement.targetSteps;

      const award = await this.prisma.achievementAward.upsert({
        where: { userId_achievementId: { userId, achievementId: achievement.id } },
        create: {
          userId,
          achievementId: achievement.id,
          progress,
          earnedAt: earned ? new Date() : null,
        },
        update: { progress, ...(earned ? { earnedAt: new Date() } : {}) },
      });

      if (earned) {
        newlyEarned.push(this.serializeEarned(achievement, award.progress, award.earnedAt!));
      }
    }
    return newlyEarned;
  }

  private serializeEarned(achievement: Achievement, progress: number, earnedAt: Date) {
    return {
      id: achievement.id,
      key: achievement.key,
      title: achievement.title,
      description: achievement.description,
      iconAsset: achievement.iconAsset,
      category: achievement.category,
      targetSteps: achievement.targetSteps,
      progress,
      earnedAt,
    };
  }
}
