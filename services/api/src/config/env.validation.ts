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

  // S14 Part 12 — optional at the class-validator level (test/dev never
  // need it), but validateEnv below hard-requires a real value in
  // production: configuration.ts used to default this to a fabricated
  // 'https://app.projectascend.com' domain that isn't real
  // infrastructure, so an operator who forgot to set it would silently
  // ship password-reset/email-verification links pointing nowhere.
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

// Hosts that are only ever correct for a developer's own machine —
// mirrors the mobile app's AppConfigValidation.unsafeHosts (S14 Part 2):
// never acceptable for DATABASE_URL or APP_PUBLIC_URL once NODE_ENV
// claims to be production.
const unsafeProductionHosts = new Set(['localhost', '127.0.0.1', '0.0.0.0']);

// A short secret is crackable regardless of whether it happens to start
// with 'dev_' — the existing prefix check below only catches the
// specific placeholder values docker-compose.yml/.env.example ship, not
// every weak secret an operator could type in its place.
const MIN_JWT_SECRET_LENGTH = 32;

function hostnameOf(url: string): string | null {
  try {
    return new URL(url).hostname.toLowerCase();
  } catch {
    return null;
  }
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

  if (validatedConfig.NODE_ENV === 'production') {
    if (
      validatedConfig.JWT_ACCESS_SECRET.length < MIN_JWT_SECRET_LENGTH ||
      validatedConfig.JWT_REFRESH_SECRET.length < MIN_JWT_SECRET_LENGTH
    ) {
      throw new Error(
        `Refusing to start in production with a JWT secret shorter than ${MIN_JWT_SECRET_LENGTH} ` +
          'characters — a short secret is crackable regardless of its content.',
      );
    }

    if (validatedConfig.JWT_ACCESS_SECRET === validatedConfig.JWT_REFRESH_SECRET) {
      throw new Error(
        'Refusing to start in production with JWT_ACCESS_SECRET and JWT_REFRESH_SECRET set ' +
          'to the same value — a leaked access token secret must never also compromise refresh ' +
          'tokens, and vice versa.',
      );
    }

    const databaseHost = hostnameOf(validatedConfig.DATABASE_URL);
    if (databaseHost !== null && unsafeProductionHosts.has(databaseHost)) {
      throw new Error(
        `Refusing to start in production with DATABASE_URL pointed at "${databaseHost}" — ` +
          'that is a local-development-only address, not a real production database.',
      );
    }

    const appPublicUrl = validatedConfig.APP_PUBLIC_URL?.trim();
    if (!appPublicUrl) {
      throw new Error(
        'Refusing to start in production with APP_PUBLIC_URL unset — password-reset and ' +
          'email-verification links are built from it, and there is no safe placeholder to ' +
          'fall back to.',
      );
    }
    const publicUrlParsed = (() => {
      try {
        return new URL(appPublicUrl);
      } catch {
        return null;
      }
    })();
    if (publicUrlParsed === null) {
      throw new Error(`APP_PUBLIC_URL "${appPublicUrl}" is not a valid URL.`);
    }
    if (publicUrlParsed.protocol !== 'https:') {
      throw new Error(
        `Refusing to start in production with APP_PUBLIC_URL using "${publicUrlParsed.protocol}//" ` +
          '— it must use https://.',
      );
    }
    if (unsafeProductionHosts.has(publicUrlParsed.hostname.toLowerCase())) {
      throw new Error(
        `Refusing to start in production with APP_PUBLIC_URL pointed at ` +
          `"${publicUrlParsed.hostname}" — that is a local-development-only address.`,
      );
    }
  }

  return validatedConfig;
}
