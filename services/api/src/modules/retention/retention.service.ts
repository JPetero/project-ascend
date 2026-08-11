import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { NotificationType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

const MS_PER_DAY = 24 * 60 * 60 * 1000;

/** A user is a win-back candidate once this many days pass with no refresh-token activity. */
export const INACTIVITY_THRESHOLD_DAYS = 14;
/** Minimum gap between two win-back notifications sent to the same user. */
export const WIN_BACK_COOLDOWN_DAYS = 14;

/**
 * Retention win-back (S13 Part 33-49) — the first scheduled/cron job in
 * this codebase (`@nestjs/schedule`), added fresh for this. Deliberately
 * does not add a new `User.lastActiveAt` column: `RefreshToken.createdAt`
 * already resets to "now" on every rotation while the app is in active
 * use (see its own doc comment in schema.prisma), so it's a real signal
 * already in the database rather than a new field that would start out
 * null/inaccurate for every existing user until their next login.
 *
 * Every notification goes through `NotificationsService.notify`, never
 * a direct Prisma write, so the master notification switch and
 * per-category opt-out preferences are enforced exactly the same way
 * they are for every other notification type in the app.
 */
@Injectable()
export class RetentionService {
  private readonly logger = new Logger(RetentionService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

  @Cron(CronExpression.EVERY_DAY_AT_9AM, { name: 'retention-win-back' })
  async runWinBackCheck(): Promise<void> {
    const candidateUserIds = await this.findWinBackCandidates();
    for (const userId of candidateUserIds) {
      await this.notifications.notify(
        userId,
        NotificationType.RE_ENGAGEMENT,
        'We miss you at Ascend',
        "Your goals are still here whenever you're ready — come back and pick up where you left off.",
      );
    }
    this.logger.log(`Retention win-back: notified ${candidateUserIds.length} inactive user(s).`);
  }

  /**
   * Users whose most recent refresh token predates the inactivity
   * threshold, excluding anyone already sent a win-back notification
   * within the cooldown window (so the daily cron doesn't renotify the
   * same inactive user every single day).
   */
  async findWinBackCandidates(now: Date = new Date()): Promise<string[]> {
    const inactivityThreshold = new Date(now.getTime() - INACTIVITY_THRESHOLD_DAYS * MS_PER_DAY);
    const cooldownThreshold = new Date(now.getTime() - WIN_BACK_COOLDOWN_DAYS * MS_PER_DAY);

    const [lastActivityByUser, recentlyNotified] = await Promise.all([
      this.prisma.refreshToken.groupBy({
        by: ['userId'],
        _max: { createdAt: true },
      }),
      this.prisma.notificationEvent.findMany({
        where: {
          type: NotificationType.RE_ENGAGEMENT,
          createdAt: { gte: cooldownThreshold },
        },
        select: { userId: true },
      }),
    ]);

    const recentlyNotifiedUserIds = new Set(recentlyNotified.map((row) => row.userId));

    return lastActivityByUser
      .filter((row) => row._max.createdAt !== null && row._max.createdAt < inactivityThreshold)
      .map((row) => row.userId)
      .filter((userId) => !recentlyNotifiedUserIds.has(userId));
  }
}
