import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleAuth } from 'google-auth-library';
import { PushConfig } from '../../../config/configuration';
import { PrismaService } from '../../../prisma/prisma.service';
import {
  DeliveryResult,
  NotificationPayload,
  PushNotificationProvider,
} from './notification-provider.interface';

/**
 * Real push delivery via the FCM HTTP v1 send API (Build Session 10
 * Part 12) — authenticated with a Firebase service-account credential
 * via `google-auth-library` (already a dependency for Google sign-in/
 * purchase verification, so no new SDK is needed). No live
 * FCM_SERVICE_ACCOUNT_JSON/FCM_PROJECT_ID exists in this environment
 * (no Firebase project has been created this session), so this code
 * path is real but untested against a live device token — see
 * build-session-10.md. Selected over NoopPushNotificationProvider by
 * NotificationsModule's factory only once both are configured.
 */
@Injectable()
export class FcmPushNotificationProvider implements PushNotificationProvider {
  private readonly logger = new Logger(FcmPushNotificationProvider.name);
  private readonly serviceAccountJson: string | undefined;
  private readonly projectId: string | undefined;
  private auth: GoogleAuth | undefined;

  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    const pushConfig = this.configService.get<PushConfig>('push')!;
    this.serviceAccountJson = pushConfig.fcmServiceAccountJson;
    this.projectId = pushConfig.fcmProjectId;
  }

  async send(userId: string, payload: NotificationPayload): Promise<DeliveryResult> {
    if (!this.serviceAccountJson || !this.projectId) {
      return { delivered: false, failureReason: 'No push provider configured.' };
    }

    const tokens = await this.prisma.pushDeviceToken.findMany({ where: { userId } });
    if (tokens.length === 0) {
      return { delivered: false, failureReason: 'No registered device for this user.' };
    }

    this.auth ??= new GoogleAuth({
      credentials: JSON.parse(this.serviceAccountJson) as Record<string, string>,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    });
    const client = await this.auth.getClient();
    const url = `https://fcm.googleapis.com/v1/projects/${this.projectId}/messages:send`;

    let deliveredCount = 0;
    let lastFailureReason: string | undefined;

    for (const token of tokens) {
      try {
        await client.request({
          url,
          method: 'POST',
          data: {
            message: {
              token: token.token,
              notification: { title: payload.title, body: payload.body },
              // FCM's `data` payload must be a flat map of strings — the
              // free-form deep-link context (e.g. a conversationId) is
              // the only field the client needs.
              ...(payload.data ? { data: { payload: payload.data } } : {}),
            },
          },
        });
        deliveredCount += 1;
      } catch (error) {
        lastFailureReason = this.describeError(error);
        // FCM reports a token as gone with HTTP 404/UNREGISTERED — that
        // token will never succeed again, so stop tracking it instead of
        // retrying it on every future notification. Duck-typed rather
        // than importing gaxios directly, since it's only a transitive
        // dependency (of google-auth-library) here.
        if (this.responseStatus(error) === 404) {
          await this.prisma.pushDeviceToken.deleteMany({ where: { id: token.id } });
        }
      }
    }

    if (deliveredCount > 0) {
      return { delivered: true };
    }

    this.logger.debug(`FCM delivery failed for ${userId}: ${lastFailureReason}`);
    return {
      delivered: false,
      failureReason: lastFailureReason ?? 'FCM rejected every registered device.',
    };
  }

  private responseStatus(error: unknown): number | undefined {
    if (typeof error !== 'object' || error === null || !('response' in error)) {
      return undefined;
    }
    const response = (error as { response?: { status?: unknown } }).response;
    return typeof response?.status === 'number' ? response.status : undefined;
  }

  private describeError(error: unknown): string {
    const status = this.responseStatus(error);
    const message = error instanceof Error ? error.message : 'Unknown FCM error.';
    return status ? `FCM error ${status}: ${message}` : message;
  }
}
