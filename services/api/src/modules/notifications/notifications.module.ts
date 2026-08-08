import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { FcmPushNotificationProvider } from './providers/fcm-push-notification.provider';
import { NoopLocalNotificationProvider } from './providers/noop-local-notification.provider';
import {
  LOCAL_NOTIFICATION_PROVIDER,
  PUSH_NOTIFICATION_PROVIDER,
} from './providers/notification-provider.interface';
import { NoopPushNotificationProvider } from './providers/noop-push-notification.provider';

/**
 * Selects the active push provider from `push.fcmServiceAccountJson` /
 * `push.fcmProjectId` — the same config-driven-factory pattern
 * MediaStorageModule uses for MEDIA_STORAGE_PROVIDER. Defaults to the
 * Noop adapter, which is also what every test in this repository runs
 * against, since no Firebase credentials exist in this environment.
 */
@Module({
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    NoopPushNotificationProvider,
    FcmPushNotificationProvider,
    {
      provide: PUSH_NOTIFICATION_PROVIDER,
      useFactory: (
        configService: ConfigService,
        noop: NoopPushNotificationProvider,
        fcm: FcmPushNotificationProvider,
      ) => {
        const push = configService.get<{ fcmServiceAccountJson?: string; fcmProjectId?: string }>(
          'push',
        );
        return push?.fcmServiceAccountJson && push.fcmProjectId ? fcm : noop;
      },
      inject: [ConfigService, NoopPushNotificationProvider, FcmPushNotificationProvider],
    },
    { provide: LOCAL_NOTIFICATION_PROVIDER, useClass: NoopLocalNotificationProvider },
  ],
  exports: [NotificationsService],
})
export class NotificationsModule {}
