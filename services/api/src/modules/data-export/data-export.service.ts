import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

/**
 * Build Session 8 Part 14 — a user-initiated export of their own
 * account data, in the spirit of GDPR/CCPA data portability. This
 * covers the primary categories a user would recognize as "my data"
 * (account, fitness, nutrition, cardio, health, achievements, social);
 * it is a representative export, not a literal dump of every table
 * this account touches (e.g. Joint Workouts and Sports Matches
 * participation are not included this session — see
 * packages/docs/build-session-8.md's platform-limitations section).
 * Every query below is scoped to the requesting user's own id; there
 * is no cross-user access path here.
 */
@Injectable()
export class DataExportService {
  constructor(private readonly prisma: PrismaService) {}

  async exportMyData(userId: string) {
    const [
      user,
      profile,
      preference,
      notificationPreference,
      workoutSessions,
      personalRecords,
      mealEntries,
      waterEntries,
      macroTarget,
      savedMeals,
      cardioSessions,
      healthMetricSamples,
      achievementAwards,
      communityProfile,
      communityPosts,
      friendshipsAsA,
      friendshipsAsB,
      directMessagesSent,
      savedNutrientArticles,
    ] = await Promise.all([
      this.prisma.user.findUnique({
        where: { id: userId },
        select: { id: true, email: true, createdAt: true },
      }),
      this.prisma.profile.findUnique({ where: { userId } }),
      this.prisma.preference.findUnique({ where: { userId } }),
      this.prisma.notificationPreference.findUnique({ where: { userId } }),
      this.prisma.workoutSession.findMany({
        where: { userId, status: 'COMPLETED' },
        include: { sets: { include: { exercise: { select: { name: true } } } } },
        orderBy: { startedAt: 'desc' },
      }),
      this.prisma.personalRecord.findMany({
        where: { userId },
        include: { exercise: { select: { name: true } } },
        orderBy: { achievedAt: 'desc' },
      }),
      this.prisma.mealEntry.findMany({
        where: { userId },
        include: { food: { select: { name: true } } },
        orderBy: { date: 'desc' },
      }),
      this.prisma.waterEntry.findMany({ where: { userId }, orderBy: { date: 'desc' } }),
      this.prisma.macroTarget.findUnique({ where: { userId } }),
      this.prisma.savedMeal.findMany({
        where: { userId },
        include: { items: { include: { food: { select: { name: true } } } } },
      }),
      this.prisma.cardioSession.findMany({
        where: { userId },
        orderBy: { startedAt: 'desc' },
      }),
      this.prisma.healthMetricSample.findMany({
        where: { userId },
        orderBy: { recordedAt: 'desc' },
      }),
      this.prisma.achievementAward.findMany({
        where: { userId, earnedAt: { not: null } },
        include: { achievement: { select: { key: true, title: true } } },
        orderBy: { earnedAt: 'desc' },
      }),
      this.prisma.communityProfile.findUnique({ where: { userId } }),
      this.prisma.communityPost.findMany({
        where: { authorId: userId },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.friendship.findMany({ where: { userAId: userId } }),
      this.prisma.friendship.findMany({ where: { userBId: userId } }),
      this.prisma.directMessage.findMany({
        where: { senderId: userId, deletedAt: null },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.savedNutrientArticle.findMany({
        where: { userId },
        include: { article: { select: { title: true, slug: true } } },
      }),
    ]);

    return {
      exportedAt: new Date().toISOString(),
      account: {
        ...user,
        profile,
        preferences: preference,
        notificationPreferences: notificationPreference,
      },
      fitness: {
        completedWorkoutSessions: workoutSessions,
        personalRecords,
      },
      nutrition: {
        mealEntries,
        waterEntries,
        macroTarget,
        savedMeals,
      },
      cardio: {
        cardioSessions,
      },
      health: {
        metricSamples: healthMetricSamples,
      },
      achievements: {
        earned: achievementAwards,
      },
      social: {
        communityProfile,
        communityPosts,
        friendIds: [
          ...friendshipsAsA.map((f) => f.userBId),
          ...friendshipsAsB.map((f) => f.userAId),
        ],
        sentMessages: directMessagesSent,
        savedNutrientArticles,
      },
    };
  }
}
