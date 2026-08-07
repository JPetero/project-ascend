import { Injectable, Logger } from '@nestjs/common';
import {
  DeliveryResult,
  LocalNotificationProvider,
  NotificationPayload,
} from './notification-provider.interface';

/**
 * Default local-notification provider — actual OS-level scheduling
 * happens on-device (see the Flutter client), so the server side is
 * honestly a no-op that just logs the reminder was generated. Kept as
 * a real interface so a server-side scheduling nudge (e.g. a silent
 * push that wakes the client to reschedule) can be added later without
 * changing NotificationsService.
 */
@Injectable()
export class NoopLocalNotificationProvider implements LocalNotificationProvider {
  private readonly logger = new Logger(NoopLocalNotificationProvider.name);

  async schedule(userId: string, payload: NotificationPayload): Promise<DeliveryResult> {
    this.logger.debug(
      `No local-notification bridge configured — reminder for ${userId}: ${payload.title}`,
    );
    return { delivered: false, failureReason: 'No local-notification bridge configured.' };
  }
}
