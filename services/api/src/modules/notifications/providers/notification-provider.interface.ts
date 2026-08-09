/**
 * Delivery abstractions for Notifications (Build Session 8 Part 12) —
 * neither implementation requires real Firebase/APNs credentials this
 * session. [PushNotificationProvider] represents a server-initiated
 * push (social events); [LocalNotificationProvider] represents a
 * device-scheduled local notification (reminders). Both interfaces are
 * real and swappable — see NoopPushNotificationProvider /
 * NoopLocalNotificationProvider for the default implementation, which
 * honestly records that no push infrastructure is configured rather
 * than pretending to deliver anything.
 */
export interface NotificationPayload {
  title: string;
  body: string;
  data?: string;
  // Build Session 11 Part 5 — the FCM data payload previously carried
  // only `data` (a bare entity id like a conversationId), with no way
  // for the client to know *what kind* of entity it was. A tapped push
  // needs both to reconstruct a deep link the same way the in-app
  // notifications inbox already does via `deepLinkPathFor` on mobile.
  type?: string;
}

export interface DeliveryResult {
  delivered: boolean;
  failureReason?: string;
}

export interface PushNotificationProvider {
  send(userId: string, payload: NotificationPayload): Promise<DeliveryResult>;
}

export interface LocalNotificationProvider {
  schedule(userId: string, payload: NotificationPayload): Promise<DeliveryResult>;
}

export const PUSH_NOTIFICATION_PROVIDER = Symbol('PUSH_NOTIFICATION_PROVIDER');
export const LOCAL_NOTIFICATION_PROVIDER = Symbol('LOCAL_NOTIFICATION_PROVIDER');
