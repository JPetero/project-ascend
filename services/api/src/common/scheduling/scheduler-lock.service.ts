import { randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

/**
 * S14 Part 9/10/11 — shared cross-instance execution lock for every
 * `@Cron` job in this codebase (RetentionService, MediaCleanupService,
 * SecurityTokenCleanupService). `@nestjs/schedule` runs entirely
 * in-process, so if the API is ever deployed with more than one
 * replica, every replica's own scheduler independently fires each job
 * on the same wall-clock schedule; without this, a scheduled job that
 * isn't naturally idempotent could run its side effects once per
 * replica.
 *
 * A lease (`ScheduledJobLock.lockedUntil`), not a session-pinned
 * Postgres advisory lock, deliberately — this works through Prisma's
 * normal pooled query interface (an advisory lock's acquire/release
 * pair must share one specific connection, which pooled queries don't
 * guarantee), and if the instance holding the lease crashes mid-run,
 * the lease simply expires instead of wedging every future run.
 */
@Injectable()
export class SchedulerLockService {
  private readonly instanceId = randomUUID();

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Runs `job` only if this instance wins the lease for `jobName`;
   * otherwise resolves to `{ ran: false }` without calling `job` at
   * all. Always releases the lease afterward (success or failure) so a
   * same-day manual retry isn't blocked for the rest of `leaseMs`.
   */
  async runExclusive<T>(
    jobName: string,
    job: () => Promise<T>,
    leaseMs = 10 * 60 * 1000,
  ): Promise<{ ran: boolean; result?: T }> {
    const acquired = await this.acquireLock(jobName, leaseMs);
    if (!acquired) {
      return { ran: false };
    }
    try {
      const result = await job();
      return { ran: true, result };
    } finally {
      await this.releaseLock(jobName);
    }
  }

  /**
   * `INSERT ... ON CONFLICT ("jobName") DO UPDATE ... WHERE "lockedUntil"
   * < now` is atomic under Postgres's row locking during the conflict
   * check — if two instances race this at the same moment, only one
   * sees the WHERE condition satisfied and gets a row affected back;
   * the loser's UPDATE is discarded exactly like ON CONFLICT DO
   * NOTHING.
   */
  private async acquireLock(jobName: string, leaseMs: number): Promise<boolean> {
    const now = new Date();
    const leaseUntil = new Date(now.getTime() + leaseMs);
    const claimed = await this.prisma.$executeRaw`
      INSERT INTO scheduled_job_locks ("jobName", "lockedUntil", "lockedBy", "updatedAt")
      VALUES (${jobName}, ${leaseUntil}, ${this.instanceId}, ${now})
      ON CONFLICT ("jobName") DO UPDATE
      SET "lockedUntil" = ${leaseUntil}, "lockedBy" = ${this.instanceId}, "updatedAt" = ${now}
      WHERE scheduled_job_locks."lockedUntil" < ${now}
    `;
    return claimed > 0;
  }

  /**
   * Expires the lease immediately (rather than deleting the row) so a
   * same-day manual re-run isn't blocked for the rest of the lease
   * duration. Scoped to this instance's id so a run that somehow
   * outlives its own lease can never clear a newer lease a different
   * instance has since claimed.
   */
  private async releaseLock(jobName: string): Promise<void> {
    await this.prisma.scheduledJobLock.updateMany({
      where: { jobName, lockedBy: this.instanceId },
      data: { lockedUntil: new Date(0) },
    });
  }
}
