import { Test } from '@nestjs/testing';
import { NotificationType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  INACTIVITY_THRESHOLD_DAYS,
  RETENTION_LOCK_NAME,
  RetentionService,
  WIN_BACK_COOLDOWN_DAYS,
} from './retention.service';

describe('RetentionService', () => {
  let service: RetentionService;
  let prisma: {
    refreshToken: { groupBy: jest.Mock };
    notificationEvent: { findMany: jest.Mock };
    scheduledJobLock: { updateMany: jest.Mock };
    $executeRaw: jest.Mock;
  };
  let notifications: { notify: jest.Mock };

  const now = new Date('2026-08-11T12:00:00.000Z');
  const daysAgo = (days: number) => new Date(now.getTime() - days * 24 * 60 * 60 * 1000);

  beforeEach(async () => {
    prisma = {
      refreshToken: { groupBy: jest.fn().mockResolvedValue([]) },
      notificationEvent: { findMany: jest.fn().mockResolvedValue([]) },
      scheduledJobLock: { updateMany: jest.fn().mockResolvedValue({ count: 1 }) },
      // Defaults to "lock acquired" (1 row affected) so every
      // pre-existing test below still exercises the real job body
      // without having to know about locking.
      $executeRaw: jest.fn().mockResolvedValue(1),
    };
    notifications = { notify: jest.fn().mockResolvedValue(undefined) };

    const moduleRef = await Test.createTestingModule({
      providers: [
        RetentionService,
        { provide: PrismaService, useValue: prisma },
        { provide: NotificationsService, useValue: notifications },
      ],
    }).compile();

    service = moduleRef.get(RetentionService);
  });

  describe('findWinBackCandidates', () => {
    it('includes a user whose last refresh token predates the inactivity threshold', async () => {
      prisma.refreshToken.groupBy.mockResolvedValue([
        { userId: 'inactive-user', _max: { createdAt: daysAgo(INACTIVITY_THRESHOLD_DAYS + 1) } },
      ]);

      const candidates = await service.findWinBackCandidates(now);

      expect(candidates).toEqual(['inactive-user']);
    });

    it('excludes a user whose last refresh token is within the inactivity threshold', async () => {
      prisma.refreshToken.groupBy.mockResolvedValue([
        { userId: 'active-user', _max: { createdAt: daysAgo(INACTIVITY_THRESHOLD_DAYS - 1) } },
      ]);

      const candidates = await service.findWinBackCandidates(now);

      expect(candidates).toEqual([]);
    });

    it('excludes an inactive user already sent a win-back notification within the cooldown', async () => {
      prisma.refreshToken.groupBy.mockResolvedValue([
        {
          userId: 'already-notified',
          _max: { createdAt: daysAgo(INACTIVITY_THRESHOLD_DAYS + 5) },
        },
      ]);
      prisma.notificationEvent.findMany.mockResolvedValue([{ userId: 'already-notified' }]);

      const candidates = await service.findWinBackCandidates(now);

      expect(candidates).toEqual([]);
      expect(prisma.notificationEvent.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            type: NotificationType.RE_ENGAGEMENT,
            createdAt: { gte: daysAgo(WIN_BACK_COOLDOWN_DAYS) },
          }),
        }),
      );
    });

    it('re-includes an inactive user once the cooldown has fully elapsed', async () => {
      prisma.refreshToken.groupBy.mockResolvedValue([
        {
          userId: 'cooldown-elapsed',
          _max: { createdAt: daysAgo(INACTIVITY_THRESHOLD_DAYS + 20) },
        },
      ]);
      prisma.notificationEvent.findMany.mockResolvedValue([]);

      const candidates = await service.findWinBackCandidates(now);

      expect(candidates).toEqual(['cooldown-elapsed']);
    });
  });

  describe('runWinBackCheck', () => {
    it('notifies every candidate through NotificationsService, never a direct Prisma write', async () => {
      prisma.refreshToken.groupBy.mockResolvedValue([
        { userId: 'user-1', _max: { createdAt: daysAgo(INACTIVITY_THRESHOLD_DAYS + 1) } },
        { userId: 'user-2', _max: { createdAt: daysAgo(INACTIVITY_THRESHOLD_DAYS + 3) } },
      ]);

      await service.runWinBackCheck();

      expect(notifications.notify).toHaveBeenCalledTimes(2);
      expect(notifications.notify).toHaveBeenCalledWith(
        'user-1',
        NotificationType.RE_ENGAGEMENT,
        expect.any(String),
        expect.any(String),
      );
      expect(notifications.notify).toHaveBeenCalledWith(
        'user-2',
        NotificationType.RE_ENGAGEMENT,
        expect.any(String),
        expect.any(String),
      );
    });

    it('notifies nobody when there are no win-back candidates', async () => {
      await service.runWinBackCheck();

      expect(notifications.notify).not.toHaveBeenCalled();
    });
  });

  describe('single-execution safety across instances (S14 Part 9)', () => {
    it('claims the lock via an INSERT ... ON CONFLICT ... WHERE targeting the job-lock row', async () => {
      await service.runWinBackCheck();

      expect(prisma.$executeRaw).toHaveBeenCalled();
      // A tagged-template call to $executeRaw is invoked as
      // $executeRaw(stringsArray, ...interpolatedValues) — the first
      // argument is the literal template segments.
      const [stringsArray] = prisma.$executeRaw.mock.calls[0] as [readonly string[]];
      const sql = stringsArray.join('?');
      expect(sql).toContain('scheduled_job_locks');
      expect(sql).toContain('ON CONFLICT');
      expect(sql).toContain('WHERE');
    });

    it('skips the candidate search entirely when the lock cannot be acquired', async () => {
      prisma.$executeRaw.mockResolvedValue(0);

      await service.runWinBackCheck();

      expect(prisma.refreshToken.groupBy).not.toHaveBeenCalled();
      expect(notifications.notify).not.toHaveBeenCalled();
    });

    it('releases the lock scoped to this instance after a successful run', async () => {
      await service.runWinBackCheck();

      expect(prisma.scheduledJobLock.updateMany).toHaveBeenCalledWith({
        where: { jobName: RETENTION_LOCK_NAME, lockedBy: expect.any(String) },
        data: { lockedUntil: new Date(0) },
      });
    });

    it('releases the lock even when notifying a candidate throws', async () => {
      prisma.refreshToken.groupBy.mockResolvedValue([
        { userId: 'user-1', _max: { createdAt: daysAgo(INACTIVITY_THRESHOLD_DAYS + 1) } },
      ]);
      notifications.notify.mockRejectedValueOnce(new Error('push provider down'));

      await expect(service.runWinBackCheck()).rejects.toThrow('push provider down');

      expect(prisma.scheduledJobLock.updateMany).toHaveBeenCalled();
    });

    it('does not attempt to release the lock when it was never acquired', async () => {
      prisma.$executeRaw.mockResolvedValue(0);

      await service.runWinBackCheck();

      expect(prisma.scheduledJobLock.updateMany).not.toHaveBeenCalled();
    });

    it('runs the job on only one of two concurrent scheduler attempts, sending no duplicate reminder', async () => {
      prisma.refreshToken.groupBy.mockResolvedValue([
        { userId: 'user-1', _max: { createdAt: daysAgo(INACTIVITY_THRESHOLD_DAYS + 1) } },
      ]);
      // Simulates two instances racing acquireLock at the same moment:
      // the real Postgres query would let exactly one INSERT ... ON
      // CONFLICT ... WHERE succeed — here that's the first call.
      prisma.$executeRaw.mockResolvedValueOnce(1).mockResolvedValueOnce(0);

      const otherInstance = new RetentionService(
        prisma as unknown as PrismaService,
        notifications as unknown as NotificationsService,
      );

      await Promise.all([service.runWinBackCheck(), otherInstance.runWinBackCheck()]);

      expect(notifications.notify).toHaveBeenCalledTimes(1);
    });
  });
});
