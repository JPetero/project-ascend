/**
 * Delivery abstraction for outbound transactional email (Build Session 9
 * Part 4) — modeled on NotificationsModule's PushNotificationProvider /
 * LocalNotificationProvider split (see
 * ../../notifications/providers/notification-provider.interface.ts): a
 * real, swappable interface with a dev-safe default that requires no
 * credentials. ConsoleEmailProvider honestly logs the attempt and reports
 * it as not delivered rather than pretending to reach an inbox; the real
 * SmtpEmailProvider is only selected when EMAIL_PROVIDER=smtp and SMTP_*
 * config is present.
 */
export interface EmailMessage {
  to: string;
  subject: string;
  text: string;
  html?: string;
}

export interface EmailDeliveryResult {
  delivered: boolean;
  failureReason?: string;
}

export interface EmailProvider {
  send(message: EmailMessage): Promise<EmailDeliveryResult>;
}

export const EMAIL_PROVIDER = Symbol('EMAIL_PROVIDER');
