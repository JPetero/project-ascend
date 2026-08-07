import { Injectable, Logger } from '@nestjs/common';
import { EmailDeliveryResult, EmailMessage, EmailProvider } from './email-provider.interface';

/**
 * Default email provider — no SMTP credentials exist in this environment,
 * so this honestly logs the attempt and reports it as not delivered
 * rather than pretending to reach an inbox. Every test in this repository
 * runs against this provider, exactly like MediaStorageModule's local
 * adapter and NotificationsModule's Noop providers.
 */
@Injectable()
export class ConsoleEmailProvider implements EmailProvider {
  private readonly logger = new Logger(ConsoleEmailProvider.name);

  async send(message: EmailMessage): Promise<EmailDeliveryResult> {
    this.logger.debug(
      `No email provider configured — would send to ${message.to}: ${message.subject}`,
    );
    return { delivered: false, failureReason: 'No email provider configured.' };
  }
}
