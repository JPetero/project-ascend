import { DeploymentEnvironment, resolveAscendEnv } from './deployment-environment';

export interface AppConfig {
  nodeEnv: string;
  // S15 Part 1 — the deployment tier (development | staging |
  // production), distinct from nodeEnv above. See
  // deployment-environment.ts's doc comment for the full model.
  ascendEnv: DeploymentEnvironment;
  port: number;
  corsOrigin: string;
  databaseUrl: string;
  jwt: {
    accessSecret: string;
    refreshSecret: string;
    accessTtl: string;
    refreshTtl: string;
  };
}

export interface MediaConfig {
  storageProvider: 'local' | 's3';
  s3Endpoint?: string;
  s3Region?: string;
  s3Bucket?: string;
  s3AccessKeyId?: string;
  s3SecretAccessKey?: string;
  s3PublicBaseUrl?: string;
}

export interface EmailConfig {
  provider: 'console' | 'smtp';
  smtpHost?: string;
  smtpPort?: number;
  smtpUser?: string;
  smtpPassword?: string;
  fromAddress?: string;
  fromName?: string;
  appPublicUrl: string;
}

export interface SocialAuthConfig {
  // The OAuth client id issued to this app in Google Cloud Console — used
  // to validate an incoming Google ID token's `aud` claim. Undefined
  // means Google sign-in is not configured this environment.
  googleClientId?: string;
  // The Services ID / bundle id registered with Apple — used to validate
  // an incoming Apple ID token's `aud` claim. Undefined means Apple
  // sign-in is not configured this environment.
  appleClientId?: string;
}

export interface AiConfig {
  // Which AiReplyProvider AssistantModule's factory selects (Build
  // Session 10 Part 14). Defaults to 'anthropic' to preserve Session 9's
  // original behavior. Whichever provider is selected still honestly
  // rejects with "not configured" if its own API key below is unset —
  // this only chooses which one is asked.
  provider: 'anthropic' | 'openai' | 'gemini';
  anthropicApiKey?: string;
  anthropicModel: string;
  openaiApiKey?: string;
  openaiModel: string;
  geminiApiKey?: string;
  geminiModel: string;
}

export interface ResearchConfig {
  // A Brave Search API subscription token, used to call the real Web
  // Search API for Research Mode (Build Session 10 Part 16). Undefined
  // means research retrieval is not configured this environment —
  // ResearchModule falls back to NoopResearchProvider, which honestly
  // rejects rather than fabricating a citation. See
  // BraveSearchResearchProvider's doc comment.
  braveSearchApiKey?: string;
}

export interface PushConfig {
  // A Firebase service-account key (the raw JSON key file content), used
  // to obtain an OAuth access token for the FCM HTTP v1 send API.
  // Undefined means remote push is not configured this environment —
  // NotificationsModule falls back to NoopPushNotificationProvider. See
  // FcmPushNotificationProvider's doc comment.
  fcmServiceAccountJson?: string;
  // The Firebase project id the FCM v1 send endpoint is scoped to
  // (https://fcm.googleapis.com/v1/projects/{fcmProjectId}/messages:send).
  fcmProjectId?: string;
}

export interface IapConfig {
  // App Store Connect shared secret, used to call Apple's verifyReceipt
  // endpoint for auto-renewable subscriptions. Undefined means Apple
  // purchase verification is not configured this environment — see
  // ApplePurchaseVerifier's doc comment.
  appleSharedSecret?: string;
  // A Google Cloud service-account key (the raw JSON key file content),
  // used to call the Google Play Developer API to verify a purchase
  // token. Undefined means Google purchase verification is not
  // configured this environment — see GooglePurchaseVerifier's doc
  // comment.
  googleServiceAccountJson?: string;
  // The Android application id (e.g. com.projectascend.app) the Google
  // Play Developer API call is scoped to.
  googlePackageName?: string;
}

export default (): {
  app: AppConfig;
  media: MediaConfig;
  email: EmailConfig;
  socialAuth: SocialAuthConfig;
  ai: AiConfig;
  research: ResearchConfig;
  push: PushConfig;
  iap: IapConfig;
} => ({
  app: {
    nodeEnv: process.env.NODE_ENV ?? 'development',
    ascendEnv: resolveAscendEnv(process.env.ASCEND_ENV, process.env.NODE_ENV ?? 'development'),
    port: parseInt(process.env.PORT ?? '3000', 10),
    corsOrigin: process.env.CORS_ORIGIN ?? '*',
    databaseUrl: process.env.DATABASE_URL ?? '',
    jwt: {
      accessSecret: process.env.JWT_ACCESS_SECRET ?? '',
      refreshSecret: process.env.JWT_REFRESH_SECRET ?? '',
      accessTtl: process.env.JWT_ACCESS_TTL ?? '15m',
      refreshTtl: process.env.JWT_REFRESH_TTL ?? '30d',
    },
  },
  media: {
    storageProvider: (process.env.MEDIA_STORAGE_PROVIDER as 'local' | 's3') ?? 'local',
    s3Endpoint: process.env.MEDIA_S3_ENDPOINT,
    s3Region: process.env.MEDIA_S3_REGION,
    s3Bucket: process.env.MEDIA_S3_BUCKET,
    s3AccessKeyId: process.env.MEDIA_S3_ACCESS_KEY_ID,
    s3SecretAccessKey: process.env.MEDIA_S3_SECRET_ACCESS_KEY,
    s3PublicBaseUrl: process.env.MEDIA_S3_PUBLIC_BASE_URL,
  },
  email: {
    provider: (process.env.EMAIL_PROVIDER as 'console' | 'smtp') ?? 'console',
    smtpHost: process.env.SMTP_HOST,
    smtpPort: process.env.SMTP_PORT ? parseInt(process.env.SMTP_PORT, 10) : undefined,
    smtpUser: process.env.SMTP_USER,
    smtpPassword: process.env.SMTP_PASSWORD,
    fromAddress: process.env.EMAIL_FROM_ADDRESS,
    fromName: process.env.EMAIL_FROM_NAME,
    // S14 Part 12 — no fabricated fallback domain: that used to let a
    // production deploy silently ship password-reset/email-verification
    // links pointing at a domain nobody owns. env.validation.ts's
    // validateEnv hard-requires a real value here in production; local
    // dev/test only ever see the console email provider, which is fine
    // with an empty prefix.
    appPublicUrl: process.env.APP_PUBLIC_URL ?? '',
  },
  socialAuth: {
    googleClientId: process.env.GOOGLE_OAUTH_CLIENT_ID,
    appleClientId: process.env.APPLE_CLIENT_ID,
  },
  ai: {
    provider: (process.env.AI_PROVIDER as 'anthropic' | 'openai' | 'gemini') ?? 'anthropic',
    anthropicApiKey: process.env.ANTHROPIC_API_KEY,
    anthropicModel: process.env.ANTHROPIC_MODEL ?? 'claude-haiku-4-5-20251001',
    openaiApiKey: process.env.OPENAI_API_KEY,
    openaiModel: process.env.OPENAI_MODEL ?? 'gpt-4o-mini',
    geminiApiKey: process.env.GEMINI_API_KEY,
    geminiModel: process.env.GEMINI_MODEL ?? 'gemini-2.0-flash-001',
  },
  research: {
    braveSearchApiKey: process.env.BRAVE_SEARCH_API_KEY,
  },
  push: {
    fcmServiceAccountJson: process.env.FCM_SERVICE_ACCOUNT_JSON,
    fcmProjectId: process.env.FCM_PROJECT_ID,
  },
  iap: {
    appleSharedSecret: process.env.APPLE_IAP_SHARED_SECRET,
    googleServiceAccountJson: process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON,
    googlePackageName: process.env.GOOGLE_PLAY_PACKAGE_NAME,
  },
});
