import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  AiConfig,
  AppConfig,
  EmailConfig,
  IapConfig,
  MediaConfig,
  PushConfig,
  ResearchConfig,
  SocialAuthConfig,
} from '../../config/configuration';
import { PrismaService } from '../../prisma/prisma.service';

/**
 * Build Session 12 Part 15-17 — read-only diagnostic for staff to check
 * "is this environment ready to run in production" without reading raw
 * env vars off a box. Reports only configured/not-configured booleans per
 * integration, never secret or key values — see FeatureFlag's neighbor
 * doc comments in this module for the same never-leak-secrets posture.
 * Mirrors the exact checks env.validation.ts already enforces at boot for
 * production, so staging/dev can see the same signal before promoting.
 */
@Injectable()
export class ReleaseReadinessService {
  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  async check() {
    const app = this.configService.get<AppConfig>('app')!;
    const media = this.configService.get<MediaConfig>('media')!;
    const email = this.configService.get<EmailConfig>('email')!;
    const socialAuth = this.configService.get<SocialAuthConfig>('socialAuth')!;
    const ai = this.configService.get<AiConfig>('ai')!;
    const research = this.configService.get<ResearchConfig>('research')!;
    const push = this.configService.get<PushConfig>('push')!;
    const iap = this.configService.get<IapConfig>('iap')!;

    const usingDevJwtSecrets =
      app.jwt.accessSecret.startsWith('dev_') || app.jwt.refreshSecret.startsWith('dev_');
    const corsWildcard = app.corsOrigin === '*';

    const [flagCount, enabledFlagCount] = await Promise.all([
      this.prisma.featureFlag.count(),
      this.prisma.featureFlag.count({ where: { enabled: true } }),
    ]);

    return {
      environment: app.nodeEnv,
      security: {
        usingDevJwtSecrets,
        corsWildcard,
        // These are hard boot-time failures in production (see
        // validateEnv) — surfaced here too so staging/dev can catch them
        // before a production promotion, not just at production boot.
        productionSafe: app.nodeEnv !== 'production' || (!usingDevJwtSecrets && !corsWildcard),
      },
      integrations: {
        mediaStorage: media.storageProvider === 's3' ? Boolean(media.s3Bucket) : true,
        email: email.provider === 'smtp' ? Boolean(email.smtpHost) : true,
        googleSignIn: Boolean(socialAuth.googleClientId),
        appleSignIn: Boolean(socialAuth.appleClientId),
        aiProvider: this.isAiProviderConfigured(ai),
        research: Boolean(research.braveSearchApiKey),
        remotePush: Boolean(push.fcmServiceAccountJson && push.fcmProjectId),
        appleIap: Boolean(iap.appleSharedSecret),
        googleIap: Boolean(iap.googleServiceAccountJson && iap.googlePackageName),
      },
      featureFlags: {
        total: flagCount,
        enabled: enabledFlagCount,
      },
    };
  }

  private isAiProviderConfigured(ai: AiConfig): boolean {
    switch (ai.provider) {
      case 'anthropic':
        return Boolean(ai.anthropicApiKey);
      case 'openai':
        return Boolean(ai.openaiApiKey);
      case 'gemini':
        return Boolean(ai.geminiApiKey);
      default:
        return false;
    }
  }
}
