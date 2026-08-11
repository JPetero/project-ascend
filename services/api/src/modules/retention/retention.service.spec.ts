import { Test } from '@nestjs/testing';
import { NotificationType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  INACTIVITY_THRESHOLD_DAYS,
  RetentionService,
  WIN_BACK_COOLDOWN_DAYS,
} from './retention.service';

describe('RetentionService', () => {
  let service: RetentionService;
  let prisma: {
    refreshToken: { groupBy: jest.Mock };
    notificationEvent: { findMany: jest.Mock };
  };
  let notifications: { notify: jest.Mock };

  const now = new Date('2026-08-11T12:00:00.000Z');
  const daysAgo = (days: number) => new Date(now.getTime() - days * 24 * 60 * 60 * 1000);

  beforeEach(async () => {
    prisma = {
      refreshToken: { groupBy: jest.fn().mockResolvedValue([]) },
      notificationEvent: { findMany: jest.fn().mockResolvedValue([]) },
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
});
