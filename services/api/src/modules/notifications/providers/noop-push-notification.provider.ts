import { Injectable, Logger } from '@nestjs/common';
import {
  DeliveryResult,
  NotificationPayload,
  PushNotificationProvider,
} from './notification-provider.interface';

/**
 * Default push provider — no Firebase/APNs credentials exist this
 * session, so this honestly logs the attempt and reports it as not
 * delivered rather than pretending to reach a device. Swappable for a
 * real provider later via NOTIFICATIONS_PUSH_PROVIDER config, the same
 * pattern MediaStorageModule's factory uses.
 */
@Injectable()
export class NoopPushNotificationProvider implements PushNotificationProvider {
  private readonly logger = new Logger(NoopPushNotificationProvider.name);

  async send(userId: string, payload: NotificationPayload): Promise<DeliveryResult> {
    this.logger.debug(`No push provider configured — would notify ${userId}: ${payload.title}`);
    return { delivered: false, failureReason: 'No push provider configured.' };
  }
}
