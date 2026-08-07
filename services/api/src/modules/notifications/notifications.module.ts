import { Module } from '@nestjs/common';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { NoopLocalNotificationProvider } from './providers/noop-local-notification.provider';
import {
  LOCAL_NOTIFICATION_PROVIDER,
  PUSH_NOTIFICATION_PROVIDER,
} from './providers/notification-provider.interface';
import { NoopPushNotificationProvider } from './providers/noop-push-notification.provider';

@Module({
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    { provide: PUSH_NOTIFICATION_PROVIDER, useClass: NoopPushNotificationProvider },
    { provide: LOCAL_NOTIFICATION_PROVIDER, useClass: NoopLocalNotificationProvider },
  ],
  exports: [NotificationsService],
})
export class NotificationsModule {}
