import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ConsoleEmailProvider } from './providers/console-email.provider';
import { EMAIL_PROVIDER } from './providers/email-provider.interface';
import { SmtpEmailProvider } from './providers/smtp-email.provider';
import { EmailService } from './email.service';

/**
 * Selects the active EmailProvider from EMAIL_PROVIDER ('console' |
 * 'smtp'), defaulting to the console adapter — the same useFactory
 * config-driven-selection pattern as MediaStorageModule.
 */
@Module({
  imports: [ConfigModule],
  providers: [
    ConsoleEmailProvider,
    SmtpEmailProvider,
    {
      provide: EMAIL_PROVIDER,
      useFactory: (
        configService: ConfigService,
        console_: ConsoleEmailProvider,
        smtp: SmtpEmailProvider,
      ) => (configService.get<string>('email.provider') === 'smtp' ? smtp : console_),
      inject: [ConfigService, ConsoleEmailProvider, SmtpEmailProvider],
    },
    EmailService,
  ],
  exports: [EmailService],
})
export class EmailModule {}
