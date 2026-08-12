import { plainToInstance } from 'class-transformer';
import {
  IsIn,
  IsNotEmpty,
  IsNumberString,
  IsOptional,
  IsString,
  validateSync,
} from 'class-validator';
import { DeploymentConfigValidation } from './deployment-config-validation';
import {
  DEPLOYMENT_ENVIRONMENTS,
  DeploymentEnvironment,
  resolveAscendEnv,
} from './deployment-environment';

class EnvironmentVariables {
  // Node/Nest's own environment signal — never a fourth 'staging' value
  // (see deployment-environment.ts's doc comment for why). Ecosystem
  // packages branch on this for production-optimized behavior; Ascend's
  // own "which real-world environment is this" signal is the separate
  // ASCEND_ENV below.
  @IsIn(['development', 'test', 'production'])
  @IsOptional()
  NODE_ENV = 'development';

  // S15 Part 1 — the deployment tier. See deployment-environment.ts's
  // doc comment for the full model and the intended NODE_ENV pairing.
  @IsIn(DEPLOYMENT_ENVIRONMENTS)
  @IsOptional()
  ASCEND_ENV: DeploymentEnvironment = 'development';

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

/**
 * Fails fast at boot if required secrets/config are missing, per the
 * "fail fast when required secrets are absent in production" requirement.
 * The deployment-environment-aware safety checks (S15 Part 2 — dev
 * secrets, weak/duplicate JWT secrets, wildcard CORS, local DATABASE_URL/
 * APP_PUBLIC_URL) live in `DeploymentConfigValidation`, which this
 * delegates to so the same checks apply identically to staging and
 * production — see that module's doc comment for why.
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

  // resolveAscendEnv applies the safety net documented on it: an
  // existing deployment with NODE_ENV=production but no ASCEND_ENV yet
  // still gets treated as a real deployed environment, not silently
  // downgraded to 'development'. Shared with configuration.ts's factory
  // so the boot-time check and the runtime AppConfig.ascendEnv value
  // (what ReleaseReadinessService etc. actually read) can never disagree.
  validatedConfig.ASCEND_ENV = resolveAscendEnv(
    config.ASCEND_ENV as string | undefined,
    validatedConfig.NODE_ENV,
  );

  const deploymentCheck = DeploymentConfigValidation.validate({
    ascendEnv: validatedConfig.ASCEND_ENV,
    nodeEnv: validatedConfig.NODE_ENV,
    jwtAccessSecret: validatedConfig.JWT_ACCESS_SECRET,
    jwtRefreshSecret: validatedConfig.JWT_REFRESH_SECRET,
    corsOrigin: validatedConfig.CORS_ORIGIN,
    databaseUrl: validatedConfig.DATABASE_URL,
    appPublicUrl: validatedConfig.APP_PUBLIC_URL,
  });
  if (!deploymentCheck.isValid) {
    throw new Error(
      `Invalid deployment configuration for ASCEND_ENV=${validatedConfig.ASCEND_ENV}:\n  - ` +
        deploymentCheck.violations.join('\n  - '),
    );
  }

  return validatedConfig;
}
