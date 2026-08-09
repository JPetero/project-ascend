import { plainToInstance } from 'class-transformer';
import {
  IsIn,
  IsNotEmpty,
  IsNumberString,
  IsOptional,
  IsString,
  validateSync,
} from 'class-validator';

class EnvironmentVariables {
  @IsIn(['development', 'test', 'production'])
  @IsOptional()
  NODE_ENV = 'development';

  @IsNumberString()
  @IsOptional()
  PORT = '3000';

  @IsString()
  @IsOptional()
  CORS_ORIGIN = '*';

  @IsString()
  @IsNotEmpty()
  DATABASE_URL!: string;

  @IsString()
  @IsNotEmpty()
  JWT_ACCESS_SECRET!: string;

  @IsString()
  @IsNotEmpty()
  JWT_REFRESH_SECRET!: string;

  @IsString()
  @IsOptional()
  JWT_ACCESS_TTL = '15m';

  @IsString()
  @IsOptional()
  JWT_REFRESH_TTL = '30d';

  // Media Platform (Build Session 8 Part 2) — all optional. Defaults to
  // the local development storage provider, which needs none of these.
  @IsIn(['local', 's3'])
  @IsOptional()
  MEDIA_STORAGE_PROVIDER = 'local';

  @IsString()
  @IsOptional()
  MEDIA_S3_ENDPOINT?: string;

  @IsString()
  @IsOptional()
  MEDIA_S3_REGION?: string;

  @IsString()
  @IsOptional()
  MEDIA_S3_BUCKET?: string;

  @IsString()
  @IsOptional()
  MEDIA_S3_ACCESS_KEY_ID?: string;

  @IsString()
  @IsOptional()
  MEDIA_S3_SECRET_ACCESS_KEY?: string;

  @IsString()
  @IsOptional()
  MEDIA_S3_PUBLIC_BASE_URL?: string;

  // Email (Build Session 9 Part 4) — all optional. Defaults to the
  // console provider, which logs instead of sending and needs no SMTP
  // credentials to run tests or a local dev server.
  @IsIn(['console', 'smtp'])
  @IsOptional()
  EMAIL_PROVIDER = 'console';

  @IsString()
  @IsOptional()
  SMTP_HOST?: string;

  @IsNumberString()
  @IsOptional()
  SMTP_PORT?: string;

  @IsString()
  @IsOptional()
  SMTP_USER?: string;

  @IsString()
  @IsOptional()
  SMTP_PASSWORD?: string;

  @IsString()
  @IsOptional()
  EMAIL_FROM_ADDRESS?: string;

  @IsString()
  @IsOptional()
  EMAIL_FROM_NAME?: string;

  @IsString()
  @IsOptional()
  APP_PUBLIC_URL?: string;

  // Google/Apple sign-in (Build Session 9 Part 8) — both optional.
  // Undefined means that provider is not configured, and its endpoint
  // honestly rejects with a "not configured" error rather than pretending
  // to work. See GoogleTokenVerifier / AppleTokenVerifier.
  @IsString()
  @IsOptional()
  GOOGLE_OAUTH_CLIENT_ID?: string;

  @IsString()
  @IsOptional()
  APPLE_CLIENT_ID?: string;

  // Live AI provider (Build Session 9 Part 15/16; Openai/Gemini added
  // Build Session 10 Part 14) — all optional. AI_PROVIDER selects which
  // adapter AssistantModule's factory uses (default 'anthropic');
  // whichever one is selected still honestly rejects with "not
  // configured" if its own key below is unset, and the mobile app's
  // aiProviderProvider falls back to the free, deterministic local
  // companion — see AssistantService and LiveAiProvider's doc comments.
  @IsIn(['anthropic', 'openai', 'gemini'])
  @IsOptional()
  AI_PROVIDER = 'anthropic';

  @IsString()
  @IsOptional()
  ANTHROPIC_API_KEY?: string;

  @IsString()
  @IsOptional()
  ANTHROPIC_MODEL?: string;

  @IsString()
  @IsOptional()
  OPENAI_API_KEY?: string;

  @IsString()
  @IsOptional()
  OPENAI_MODEL?: string;

  @IsString()
  @IsOptional()
  GEMINI_API_KEY?: string;

  @IsString()
  @IsOptional()
  GEMINI_MODEL?: string;

  // Research Mode retrieval (Build Session 10 Part 16) — optional.
  // Undefined means ResearchModule falls back to NoopResearchProvider,
  // which honestly rejects with "not configured" rather than fabricating
  // a citation. See BraveSearchResearchProvider.
  @IsString()
  @IsOptional()
  BRAVE_SEARCH_API_KEY?: string;

  // Store purchase verification (Build Session 9 Part 17/18) — both
  // optional. Undefined means that platform's purchase verifier
  // honestly rejects with "not configured" rather than pretending a
  // purchase was verified. See ApplePurchaseVerifier /
  // GooglePurchaseVerifier.
  @IsString()
  @IsOptional()
  APPLE_IAP_SHARED_SECRET?: string;

  @IsString()
  @IsOptional()
  GOOGLE_PLAY_SERVICE_ACCOUNT_JSON?: string;

  @IsString()
  @IsOptional()
  GOOGLE_PLAY_PACKAGE_NAME?: string;

  // Remote push notifications (Build Session 10 Part 12) — optional.
  // Undefined means NotificationsModule falls back to
  // NoopPushNotificationProvider, which honestly records "not
  // configured" instead of pretending to deliver a push. See
  // FcmPushNotificationProvider.
  @IsString()
  @IsOptional()
  FCM_SERVICE_ACCOUNT_JSON?: string;

  @IsString()
  @IsOptional()
  FCM_PROJECT_ID?: string;
}

/**
 * Fails fast at boot if required secrets/config are missing, per the
 * "fail fast when required secrets are absent in production" requirement.
 */
export function validateEnv(config: Record<string, unknown>) {
  const validatedConfig = plainToInstance(EnvironmentVariables, config, {
    enableImplicitConversion: true,
  });
  const errors = validateSync(validatedConfig, { skipMissingProperties: false });

  if (errors.length > 0) {
    const details = errors
      .flatMap((error) => Object.values(error.constraints ?? {}))
      .join('\n  - ');
    throw new Error(`Invalid environment configuration:\n  - ${details}`);
  }

  if (
    validatedConfig.NODE_ENV === 'production' &&
    (validatedConfig.JWT_ACCESS_SECRET.startsWith('dev_') ||
      validatedConfig.JWT_REFRESH_SECRET.startsWith('dev_'))
  ) {
    throw new Error('Refusing to start in production with development JWT secrets.');
  }

  if (validatedConfig.NODE_ENV === 'production' && validatedConfig.CORS_ORIGIN === '*') {
    throw new Error(
      'Refusing to start in production with CORS_ORIGIN unset or "*" — set it to an ' +
        'explicit comma-separated allowlist of origins.',
    );
  }

  return validatedConfig;
}
