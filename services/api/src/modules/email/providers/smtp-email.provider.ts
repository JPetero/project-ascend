import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import { EmailConfig } from '../../../config/configuration';
import { EmailDeliveryResult, EmailMessage, EmailProvider } from './email-provider.interface';

/**
 * Real SMTP-backed email provider, selected via EMAIL_PROVIDER=smtp. Only
 * instantiates a transport lazily, on first send — no credentials exist
 * in this development/test environment, so this code path is untested
 * against a live mail server this session (see build-session-9.md).
 */
@Injectable()
export class SmtpEmailProvider implements EmailProvider {
  private readonly logger = new Logger(SmtpEmailProvider.name);
  private readonly emailConfig: EmailConfig;
  private transport: nodemailer.Transporter | undefined;

  constructor(private readonly configService: ConfigService) {
    this.emailConfig = this.configService.get<EmailConfig>('email')!;
  }

  async send(message: EmailMessage): Promise<EmailDeliveryResult> {
    if (!this.emailConfig.smtpHost || !this.emailConfig.fromAddress) {
      this.logger.warn(
        'SMTP provider selected but SMTP_HOST/EMAIL_FROM_ADDRESS is not configured.',
      );
      return { delivered: false, failureReason: 'SMTP is not fully configured.' };
    }

    try {
      const transport = this.getTransport();
      await transport.sendMail({
        from: this.emailConfig.fromName
          ? `"${this.emailConfig.fromName}" <${this.emailConfig.fromAddress}>`
          : this.emailConfig.fromAddress,
        to: message.to,
        subject: message.subject,
        text: message.text,
        html: message.html,
      });
      return { delivered: true };
    } catch (error) {
      const reason = error instanceof Error ? error.message : 'Unknown SMTP error.';
      this.logger.error(`Failed to send email to ${message.to}: ${reason}`);
      return { delivered: false, failureReason: reason };
    }
  }

  private getTransport(): nodemailer.Transporter {
    if (!this.transport) {
      this.transport = nodemailer.createTransport({
        host: this.emailConfig.smtpHost,
        port: this.emailConfig.smtpPort ?? 587,
        secure: (this.emailConfig.smtpPort ?? 587) === 465,
        auth: this.emailConfig.smtpUser
          ? { user: this.emailConfig.smtpUser, pass: this.emailConfig.smtpPassword }
          : undefined,
      });
    }
    return this.transport;
  }
}
