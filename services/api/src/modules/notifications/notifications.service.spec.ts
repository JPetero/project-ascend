import { Test } from '@nestjs/testing';
import { NotificationType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from './notifications.service';
import {
  LOCAL_NOTIFICATION_PROVIDER,
  PUSH_NOTIFICATION_PROVIDER,
} from './providers/notification-provider.interface';

describe('NotificationsService', () => {
  let service: NotificationsService;
  let prisma: {
    notificationPreference: { findUnique: jest.Mock; create: jest.Mock; update: jest.Mock };
    preference: { findUnique: jest.Mock };
    notificationEvent: {
      findMany: jest.Mock;
      count: jest.Mock;
      create: jest.Mock;
      updateMany: jest.Mock;
    };
    notificationDelivery: { create: jest.Mock };
  };
  let pushProvider: { send: jest.Mock };
  let localProvider: { schedule: jest.Mock };

  beforeEach(async () => {
    prisma = {
      notificationPreference: {
        findUnique: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      preference: { findUnique: jest.fn().mockResolvedValue({ notificationsEnabled: true }) },
      notificationEvent: {
        findMany: jest.fn().mockResolvedValue([]),
        count: jest.fn(),
        create: jest.fn(),
        updateMany: jest.fn(),
      },
      notificationDelivery: { create: jest.fn() },
    };
    pushProvider = { send: jest.fn().mockResolvedValue({ delivered: false }) };
    localProvider = { schedule: jest.fn().mockResolvedValue({ delivered: false }) };

    const moduleRef = await Test.createTestingModule({
      providers: [
        NotificationsService,
        { provide: PrismaService, useValue: prisma },
        { provide: PUSH_NOTIFICATION_PROVIDER, useValue: pushProvider },
        { provide: LOCAL_NOTIFICATION_PROVIDER, useValue: localProvider },
      ],
    }).compile();

    service = moduleRef.get(NotificationsService);

    prisma.notificationPreference.findUnique.mockResolvedValue({
      userId: 'user-1',
      workoutReminders: true,
      restDayReminders: true,
      waterReminders: true,
      mealReminders: true,
      achievementNotifications: true,
      socialNotifications: true,
    });
  });

  describe('getPreferences', () => {
    it('creates a default row when none exists', async () => {
      prisma.notificationPreference.findUnique.mockResolvedValue(null);
      prisma.notificationPreference.create.mockResolvedValue({ userId: 'user-1' });

      const result = await service.getPreferences('user-1');

      expect(prisma.notificationPreference.create).toHaveBeenCalledWith({
        data: { userId: 'user-1' },
      });
      expect(result).toEqual({ userId: 'user-1' });
    });

    it('returns the existing row without creating one', async () => {
      await service.getPreferences('user-1');

      expect(prisma.notificationPreference.create).not.toHaveBeenCalled();
    });
  });

  describe('notify', () => {
    it('creates no event when the master notificationsEnabled switch is off', async () => {
      prisma.preference.findUnique.mockResolvedValue({ notificationsEnabled: false });

      await service.notify('user-1', NotificationType.FRIEND_REQUEST, 'Title', 'Body');

      expect(prisma.notificationEvent.create).not.toHaveBeenCalled();
    });

    it('creates no event when the specific category is disabled', async () => {
      prisma.notificationPreference.findUnique.mockResolvedValue({
        userId: 'user-1',
        workoutReminders: false,
        restDayReminders: true,
        waterReminders: true,
        mealReminders: true,
        achievementNotifications: true,
        socialNotifications: true,
      });

      await service.notify('user-1', NotificationType.WORKOUT_REMINDER, 'Title', 'Body');

      expect(prisma.notificationEvent.create).not.toHaveBeenCalled();
    });

    it('routes reminder types through the local provider', async () => {
      prisma.notificationEvent.create.mockResolvedValue({ id: 'event-1' });

      await service.notify('user-1', NotificationType.WATER_REMINDER, 'Drink up', 'Stay hydrated.');

      expect(localProvider.schedule).toHaveBeenCalled();
      expect(pushProvider.send).not.toHaveBeenCalled();
      expect(prisma.notificationDelivery.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ channel: 'LOCAL', status: 'FAILED' }),
        }),
      );
    });

    it('routes social types through the push provider', async () => {
      prisma.notificationEvent.create.mockResolvedValue({ id: 'event-1' });

      await service.notify('user-1', NotificationType.FRIEND_REQUEST, 'New friend request', 'Body');

      expect(pushProvider.send).toHaveBeenCalled();
      expect(localProvider.schedule).not.toHaveBeenCalled();
    });
  });

  describe('markRead / unreadCount', () => {
    it('scopes markRead to the caller', async () => {
      await service.markRead('user-1', 'event-1');

      expect(prisma.notificationEvent.updateMany).toHaveBeenCalledWith({
        where: { id: 'event-1', userId: 'user-1' },
        data: { readAt: expect.any(Date) },
      });
    });

    it('counts unread events for the caller', async () => {
      prisma.notificationEvent.count.mockResolvedValue(3);

      const count = await service.unreadCount('user-1');

      expect(count).toBe(3);
    });
  });
});
