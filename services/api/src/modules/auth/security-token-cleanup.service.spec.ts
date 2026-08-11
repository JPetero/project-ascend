import { Test } from '@nestjs/testing';
import { SchedulerLockService } from '../../common/scheduling/scheduler-lock.service';
import { PrismaService } from '../../prisma/prisma.service';
import {
  SECURITY_TOKEN_CLEANUP_LOCK_NAME,
  SecurityTokenCleanupService,
} from './security-token-cleanup.service';

describe('SecurityTokenCleanupService', () => {
  let service: SecurityTokenCleanupService;
  let prisma: {
    passwordResetToken: { count: jest.Mock; deleteMany: jest.Mock };
    emailVerificationToken: { count: jest.Mock; deleteMany: jest.Mock };
    refreshToken: { count: jest.Mock; deleteMany: jest.Mock };
    pushDeviceToken: { count: jest.Mock; deleteMany: jest.Mock };
  };
  let schedulerLock: { runExclusive: jest.Mock };

  beforeEach(async () => {
    prisma = {
      passwordResetToken: {
        count: jest.fn().mockResolvedValue(0),
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
      emailVerificationToken: {
        count: jest.fn().mockResolvedValue(0),
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
      refreshToken: {
        count: jest.fn().mockResolvedValue(0),
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
      pushDeviceToken: {
        count: jest.fn().mockResolvedValue(0),
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
    };
    schedulerLock = {
      runExclusive: jest.fn(async (_name: string, job: () => Promise<unknown>) => ({
        ran: true,
        result: await job(),
      })),
    };

    const moduleRef = await Test.createTestingModule({
      providers: [
        SecurityTokenCleanupService,
        { provide: PrismaService, useValue: prisma },
        { provide: SchedulerLockService, useValue: schedulerLock },
      ],
    }).compile();

    service = moduleRef.get(SecurityTokenCleanupService);
  });

  describe('runCleanup dryRun mode', () => {
    it('counts without deleting anything', async () => {
      prisma.passwordResetToken.count.mockResolvedValue(2);
      prisma.emailVerificationToken.count.mockResolvedValue(1);
      prisma.refreshToken.count.mockResolvedValue(5);
      prisma.pushDeviceToken.count.mockResolvedValue(3);

      const counts = await service.runCleanup({ dryRun: true });

      expect(counts).toEqual({
        passwordResetTokens: 2,
        emailVerificationTokens: 1,
        refreshTokens: 5,
        pushDeviceTokens: 3,
      });
      expect(prisma.passwordResetToken.deleteMany).not.toHaveBeenCalled();
      expect(prisma.emailVerificationToken.deleteMany).not.toHaveBeenCalled();
      expect(prisma.refreshToken.deleteMany).not.toHaveBeenCalled();
      expect(prisma.pushDeviceToken.deleteMany).not.toHaveBeenCalled();
    });
  });

  describe('runCleanup real deletion', () => {
    it('deletes expired password reset tokens past the grace period', async () => {
      prisma.passwordResetToken.deleteMany.mockResolvedValue({ count: 4 });

      const counts = await service.runCleanup({ dryRun: false });

      expect(counts.passwordResetTokens).toBe(4);
      expect(prisma.passwordResetToken.deleteMany).toHaveBeenCalledWith({
        where: { expiresAt: { lt: expect.any(Date) } },
      });
    });

    it('deletes expired email verification tokens past the grace period', async () => {
      prisma.emailVerificationToken.deleteMany.mockResolvedValue({ count: 2 });

      const counts = await service.runCleanup({ dryRun: false });

      expect(counts.emailVerificationTokens).toBe(2);
    });

    it('deletes expired refresh tokens regardless of revokedAt, since expiry alone makes them unusable', async () => {
      prisma.refreshToken.deleteMany.mockResolvedValue({ count: 10 });

      const counts = await service.runCleanup({ dryRun: false });

      expect(counts.refreshTokens).toBe(10);
      const [args] = prisma.refreshToken.deleteMany.mock.calls[0] as [{ where: unknown }];
      expect(args.where).toEqual({ expiresAt: { lt: expect.any(Date) } });
      expect(args.where).not.toHaveProperty('revokedAt');
    });

    it('deletes push device tokens stale past the grace period', async () => {
      prisma.pushDeviceToken.deleteMany.mockResolvedValue({ count: 7 });

      const counts = await service.runCleanup({ dryRun: false });

      expect(counts.pushDeviceTokens).toBe(7);
      expect(prisma.pushDeviceToken.deleteMany).toHaveBeenCalledWith({
        where: { lastSeenAt: { lt: expect.any(Date) } },
      });
    });
  });

  describe('runScheduledCleanup', () => {
    it('runs through SchedulerLockService keyed by SECURITY_TOKEN_CLEANUP_LOCK_NAME', async () => {
      await service.runScheduledCleanup();

      expect(schedulerLock.runExclusive).toHaveBeenCalledWith(
        SECURITY_TOKEN_CLEANUP_LOCK_NAME,
        expect.any(Function),
      );
    });

    it('does nothing when another instance already holds the lock', async () => {
      schedulerLock.runExclusive.mockResolvedValue({ ran: false });

      await service.runScheduledCleanup();

      expect(prisma.refreshToken.deleteMany).not.toHaveBeenCalled();
    });
  });
});
