import { Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EmailConfig } from '../../config/configuration';
import {
  EMAIL_PROVIDER,
  EmailDeliveryResult,
  EmailProvider,
} from './providers/email-provider.interface';

/**
 * The single entry point every module calls to send transactional email
 * (Build Session 9 Part 4) — mirrors NotificationsService being the one
 * caller-facing surface in front of swappable delivery providers. Builds
 * the actual subject/text/html for each transactional email type so
 * callers (AuthService) never construct message copy themselves.
 */
@Injectable()
export class EmailService {
  private readonly appPublicUrl: string;

  constructor(
    @Inject(EMAIL_PROVIDER) private readonly provider: EmailProvider,
    private readonly configService: ConfigService,
  ) {
    this.appPublicUrl = this.configService.get<EmailConfig>('email')!.appPublicUrl;
  }

  async sendPasswordResetEmail(to: string, token: string): Promise<EmailDeliveryResult> {
    const link = `${this.appPublicUrl}/reset-password?token=${encodeURIComponent(token)}`;
    return this.provider.send({
      to,
      subject: 'Reset your Project Ascend password',
      text: `We received a request to reset your Project Ascend password. Use this link within the next hour: ${link}\n\nIf you didn't request this, you can safely ignore this email — your password will not change.`,
      html: `<p>We received a request to reset your Project Ascend password.</p><p><a href="${link}">Reset your password</a></p><p>This link expires in one hour. If you didn't request this, you can safely ignore this email — your password will not change.</p>`,
    });
  }

  async sendVerificationEmail(to: string, token: string): Promise<EmailDeliveryResult> {
    const link = `${this.appPublicUrl}/verify-email?token=${encodeURIComponent(token)}`;
    return this.provider.send({
      to,
      subject: 'Verify your Project Ascend email address',
      text: `Confirm this is your email address to finish setting up your Project Ascend account: ${link}\n\nThis link expires in 24 hours.`,
      html: `<p>Confirm this is your email address to finish setting up your Project Ascend account.</p><p><a href="${link}">Verify email address</a></p><p>This link expires in 24 hours.</p>`,
    });
  }
}
