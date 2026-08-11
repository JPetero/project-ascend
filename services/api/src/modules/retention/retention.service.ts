import { randomUUID } from 'node:crypto';
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
/** Name of this job's row in ScheduledJobLock — see acquireLock's doc comment. */
export const RETENTION_LOCK_NAME = 'retention-win-back';
/**
 * How long a claimed lease is honored before it's considered stale and
 * reclaimable. Comfortably longer than this job should ever take to
 * run (it does a handful of DB reads plus one notify() call per
 * candidate), but short enough that an instance that crashed mid-run
 * doesn't block the next day's scheduled run for long if it were ever
 * retried sooner.
 */
export const RETENTION_LOCK_LEASE_MS = 10 * 60 * 1000;

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
 * a direct Prisma write, so the master notification switch is enforced
 * exactly the same way it is for every other notification type in the
 * app. Unlike every other category, though, `RE_ENGAGEMENT` is gated by
 * an opt-**in** preference (`NotificationPreference.reEngagementReminders`,
 * default false) rather than an opt-out one — S14 Part 8 — so this job
 * only ever reaches a user who affirmatively asked to hear "come back
 * whenever you're ready." No guilt-based copy ("you're losing your
 * streak," "we need you back") is used here or should ever be added.
 */
@Injectable()
export class RetentionService {
  private readonly logger = new Logger(RetentionService.name);
  // One id per running process — identifies which instance currently
  // holds the lease, so releaseLock only ever clears a lease this same
  // instance acquired (never a newer lease another instance claimed
  // after this one's expired).
  private readonly instanceId = randomUUID();

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

  @Cron(CronExpression.EVERY_DAY_AT_9AM, { name: 'retention-win-back' })
  async runWinBackCheck(): Promise<void> {
    const acquired = await this.acquireLock();
    if (!acquired) {
      this.logger.log(
        'Retention win-back: another instance already holds the lock for this run, skipping.',
      );
      return;
    }
    try {
      const candidateUserIds = await this.findWinBackCandidates();
      for (const userId of candidateUserIds) {
        await this.notifications.notify(
          userId,
          NotificationType.RE_ENGAGEMENT,
          "Ascend is here whenever you're ready",
          "Your workouts and progress are still available whenever you'd like to continue.",
        );
      }
      this.logger.log(`Retention win-back: notified ${candidateUserIds.length} inactive user(s).`);
    } finally {
      await this.releaseLock();
    }
  }

  /**
   * S14 Part 9 — single-execution safety across replicas. `@nestjs/schedule`
   * runs entirely in-process, so if the API is deployed with more than one
   * instance, every instance's own scheduler fires this job at 9am
   * independently; without a cross-instance lock, an inactive user could
   * get one win-back notification per replica. `INSERT ... ON CONFLICT
   * ("jobName") DO UPDATE ... WHERE "lockedUntil" < now` is atomic under
   * Postgres's row locking during the conflict check, so if two instances
   * race this at the same moment, only one sees the WHERE condition
   * satisfied and gets a row affected back — the loser's UPDATE is
   * discarded exactly like ON CONFLICT DO NOTHING, without needing a
   * session-pinned advisory lock (which would require every lock/unlock
   * call to share one specific pooled connection).
   */
  private async acquireLock(): Promise<boolean> {
    const now = new Date();
    const leaseUntil = new Date(now.getTime() + RETENTION_LOCK_LEASE_MS);
    const claimed = await this.prisma.$executeRaw`
      INSERT INTO scheduled_job_locks ("jobName", "lockedUntil", "lockedBy", "updatedAt")
      VALUES (${RETENTION_LOCK_NAME}, ${leaseUntil}, ${this.instanceId}, ${now})
      ON CONFLICT ("jobName") DO UPDATE
      SET "lockedUntil" = ${leaseUntil}, "lockedBy" = ${this.instanceId}, "updatedAt" = ${now}
      WHERE scheduled_job_locks."lockedUntil" < ${now}
    `;
    return claimed > 0;
  }

  /**
   * Expires the lease immediately (rather than deleting the row) so a
   * same-day manual re-run isn't blocked for the rest of the lease
   * duration. Scoped to `lockedBy: this.instanceId` so a run that
   * somehow outlives its own lease can never clear a newer lease a
   * different instance has since claimed.
   */
  private async releaseLock(): Promise<void> {
    await this.prisma.scheduledJobLock.updateMany({
      where: { jobName: RETENTION_LOCK_NAME, lockedBy: this.instanceId },
      data: { lockedUntil: new Date(0) },
    });
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
