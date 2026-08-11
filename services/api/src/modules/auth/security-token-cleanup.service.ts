import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { SchedulerLockService } from '../../common/scheduling/scheduler-lock.service';
import { PrismaService } from '../../prisma/prisma.service';

const MS_PER_DAY = 24 * 60 * 60 * 1000;

/** Name of this job's row in ScheduledJobLock — see SchedulerLockService's doc comment. */
export const SECURITY_TOKEN_CLEANUP_LOCK_NAME = 'security-token-cleanup';

/** PasswordResetToken/EmailVerificationToken are single-use and short-lived by design; kept a week past expiry purely for support/debugging convenience. */
export const EXPIRED_SHORT_LIVED_TOKEN_GRACE_DAYS = 7;
/**
 * RefreshToken. `AuthService.refresh` rejects an expired token before
 * it ever reaches reuse-detection logic (`stored.expiresAt < new Date()`
 * short-circuits first) — so an expired row carries no further
 * security value regardless of `revokedAt`/`reusedAt`; the actual
 * reuse-detection audit trail lives in `AuditEvent`
 * (`auth.refresh_token_reuse_detected`), not in this table. The grace
 * period here is for support/debugging convenience only.
 */
export const EXPIRED_REFRESH_TOKEN_GRACE_DAYS = 30;
/** A push token nobody has refreshed/re-registered in this long is almost certainly stale (uninstalled app, OS-rotated token) — FCM/APNs both expect stale tokens to eventually stop being used. */
export const STALE_PUSH_DEVICE_TOKEN_GRACE_DAYS = 90;

export interface SecurityTokenCleanupCounts {
  passwordResetTokens: number;
  emailVerificationTokens: number;
  refreshTokens: number;
  pushDeviceTokens: number;
}

/**
 * S14 Part 11 — expired/stale security token cleanup. None of these
 * tables are audit or legal records (that's `AuditEvent`, untouched
 * here) — they're working state whose only purpose is validating a
 * live token or push send, so once a row can no longer serve that
 * purpose, keeping it forever only adds table bloat.
 */
@Injectable()
export class SecurityTokenCleanupService {
  private readonly logger = new Logger(SecurityTokenCleanupService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly schedulerLock: SchedulerLockService,
  ) {}

  @Cron(CronExpression.EVERY_DAY_AT_4AM, { name: 'security-token-cleanup' })
  async runScheduledCleanup(): Promise<void> {
    const { ran, result } = await this.schedulerLock.runExclusive(
      SECURITY_TOKEN_CLEANUP_LOCK_NAME,
      () => this.runCleanup({ dryRun: false }),
    );
    if (!ran) {
      this.logger.log('Security token cleanup: another instance already holds the lock, skipping.');
      return;
    }
    this.logger.log(`Security token cleanup: ${JSON.stringify(result)}`);
  }

  /** Safe to call directly with `dryRun: true` to preview counts without deleting anything. */
  async runCleanup({ dryRun }: { dryRun: boolean }): Promise<SecurityTokenCleanupCounts> {
    const [passwordResetTokens, emailVerificationTokens, refreshTokens, pushDeviceTokens] =
      await Promise.all([
        this.cleanPasswordResetTokens(dryRun),
        this.cleanEmailVerificationTokens(dryRun),
        this.cleanRefreshTokens(dryRun),
        this.cleanPushDeviceTokens(dryRun),
      ]);
    return { passwordResetTokens, emailVerificationTokens, refreshTokens, pushDeviceTokens };
  }

  private async cleanPasswordResetTokens(dryRun: boolean): Promise<number> {
    const where = {
      expiresAt: { lt: this.cutoff(EXPIRED_SHORT_LIVED_TOKEN_GRACE_DAYS) },
    };
    if (dryRun) return this.prisma.passwordResetToken.count({ where });
    const { count } = await this.prisma.passwordResetToken.deleteMany({ where });
    return count;
  }

  private async cleanEmailVerificationTokens(dryRun: boolean): Promise<number> {
    const where = {
      expiresAt: { lt: this.cutoff(EXPIRED_SHORT_LIVED_TOKEN_GRACE_DAYS) },
    };
    if (dryRun) return this.prisma.emailVerificationToken.count({ where });
    const { count } = await this.prisma.emailVerificationToken.deleteMany({ where });
    return count;
  }

  private async cleanRefreshTokens(dryRun: boolean): Promise<number> {
    const where = {
      expiresAt: { lt: this.cutoff(EXPIRED_REFRESH_TOKEN_GRACE_DAYS) },
    };
    if (dryRun) return this.prisma.refreshToken.count({ where });
    const { count } = await this.prisma.refreshToken.deleteMany({ where });
    return count;
  }

  private async cleanPushDeviceTokens(dryRun: boolean): Promise<number> {
    const where = {
      lastSeenAt: { lt: this.cutoff(STALE_PUSH_DEVICE_TOKEN_GRACE_DAYS) },
    };
    if (dryRun) return this.prisma.pushDeviceToken.count({ where });
    const { count } = await this.prisma.pushDeviceToken.deleteMany({ where });
    return count;
  }

  private cutoff(graceDays: number): Date {
    return new Date(Date.now() - graceDays * MS_PER_DAY);
  }
}
