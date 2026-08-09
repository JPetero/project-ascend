import { Inject, Injectable } from '@nestjs/common';
import { NotificationChannel, NotificationDeliveryStatus, NotificationType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';
import { UpdateNotificationPreferencesDto } from './dto/update-notification-preferences.dto';
import {
  LOCAL_NOTIFICATION_PROVIDER,
  LocalNotificationProvider,
  PUSH_NOTIFICATION_PROVIDER,
  PushNotificationProvider,
} from './providers/notification-provider.interface';

const REMINDER_TYPES = new Set<NotificationType>([
  NotificationType.WORKOUT_REMINDER,
  NotificationType.REST_DAY_REMINDER,
  NotificationType.WATER_REMINDER,
  NotificationType.MEAL_REMINDER,
]);

/**
 * Notifications (Build Session 8 Part 12) — the single entry point
 * every other module calls to raise a notification is [notify]. It
 * always checks `Preference.notificationsEnabled` (the existing master
 * switch) and the per-category NotificationPreference before ever
 * creating a NotificationEvent, so an opted-out category truly creates
 * nothing rather than being created-then-suppressed.
 */
@Injectable()
export class NotificationsService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(PUSH_NOTIFICATION_PROVIDER) private readonly pushProvider: PushNotificationProvider,
    @Inject(LOCAL_NOTIFICATION_PROVIDER) private readonly localProvider: LocalNotificationProvider,
  ) {}

  async getPreferences(userId: string) {
    const existing = await this.prisma.notificationPreference.findUnique({ where: { userId } });
    if (existing) return existing;
    return this.prisma.notificationPreference.create({ data: { userId } });
  }

  async updatePreferences(userId: string, dto: UpdateNotificationPreferencesDto) {
    await this.getPreferences(userId);
    return this.prisma.notificationPreference.update({ where: { userId }, data: dto });
  }

  async listEvents(userId: string, unreadOnly = false) {
    return this.prisma.notificationEvent.findMany({
      where: { userId, ...(unreadOnly ? { readAt: null } : {}) },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
  }

  async unreadCount(userId: string): Promise<number> {
    return this.prisma.notificationEvent.count({ where: { userId, readAt: null } });
  }

  async markRead(userId: string, eventId: string): Promise<void> {
    await this.prisma.notificationEvent.updateMany({
      where: { id: eventId, userId },
      data: { readAt: new Date() },
    });
  }

  async markAllRead(userId: string): Promise<void> {
    await this.prisma.notificationEvent.updateMany({
      where: { userId, readAt: null },
      data: { readAt: new Date() },
    });
  }

  /**
   * Registers (or refreshes) the caller's remote push token (Build
   * Session 10 Part 12). Upserts on the token itself, not
   * userId+token, because a provider-issued token belongs to exactly
   * one installation at a time — re-registering the same token under a
   * different account (reinstall, account switch) moves it rather than
   * creating a stale duplicate that FCM would still deliver to.
   */
  async registerDeviceToken(userId: string, dto: RegisterDeviceTokenDto): Promise<void> {
    await this.prisma.pushDeviceToken.upsert({
      where: { token: dto.token },
      create: { userId, token: dto.token, platform: dto.platform },
      update: { userId, platform: dto.platform, lastSeenAt: new Date() },
    });
  }

  /** Scoped to the caller's own tokens — never lets one user remove another's. */
  async unregisterDeviceToken(userId: string, token: string): Promise<void> {
    await this.prisma.pushDeviceToken.deleteMany({ where: { userId, token } });
  }

  async notify(
    userId: string,
    type: NotificationType,
    title: string,
    body: string,
    data?: string,
  ): Promise<void> {
    const allowed = await this.isEnabledFor(userId, type);
    if (!allowed) return;

    const event = await this.prisma.notificationEvent.create({
      data: { userId, type, title, body, data },
    });

    const channel = REMINDER_TYPES.has(type) ? NotificationChannel.LOCAL : NotificationChannel.PUSH;
    const result =
      channel === NotificationChannel.LOCAL
        ? await this.localProvider.schedule(userId, { title, body, data })
        : await this.pushProvider.send(userId, { title, body, data, type });

    await this.prisma.notificationDelivery.create({
      data: {
        eventId: event.id,
        channel,
        status: result.delivered
          ? NotificationDeliveryStatus.SENT
          : NotificationDeliveryStatus.FAILED,
        deliveredAt: result.delivered ? new Date() : null,
        failureReason: result.failureReason,
      },
    });
  }

  private async isEnabledFor(userId: string, type: NotificationType): Promise<boolean> {
    const [preference, generalPreference] = await Promise.all([
      this.getPreferences(userId),
      this.prisma.preference.findUnique({ where: { userId } }),
    ]);
    if (generalPreference && !generalPreference.notificationsEnabled) return false;

    switch (type) {
      case NotificationType.WORKOUT_REMINDER:
        return preference.workoutReminders;
      case NotificationType.REST_DAY_REMINDER:
        return preference.restDayReminders;
      case NotificationType.WATER_REMINDER:
        return preference.waterReminders;
      case NotificationType.MEAL_REMINDER:
        return preference.mealReminders;
      case NotificationType.ACHIEVEMENT_UNLOCKED:
        return preference.achievementNotifications;
      // Support/moderation/promote/eligibility updates (Build Session 12
      // Part 2) share the same catch-all bucket every other non-reminder
      // category already uses (friend requests, DMs, group invites,
      // etc.) — there's no dedicated preference column for them, and
      // adding one is a bigger, separate product decision than this
      // Part's scope.
      default:
        return preference.socialNotifications;
    }
  }
}
