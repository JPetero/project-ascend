export interface AppConfig {
  nodeEnv: string;
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
  // Undefined means no live AI provider is configured this environment —
  // AssistantService honestly rejects with "not configured" rather than
  // pretending to generate a reply (see AssistantService's doc comment).
  anthropicApiKey?: string;
  anthropicModel: string;
}

export default (): {
  app: AppConfig;
  media: MediaConfig;
  email: EmailConfig;
  socialAuth: SocialAuthConfig;
  ai: AiConfig;
} => ({
  app: {
    nodeEnv: process.env.NODE_ENV ?? 'development',
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
    appPublicUrl: process.env.APP_PUBLIC_URL ?? 'https://app.projectascend.com',
  },
  socialAuth: {
    googleClientId: process.env.GOOGLE_OAUTH_CLIENT_ID,
    appleClientId: process.env.APPLE_CLIENT_ID,
  },
  ai: {
    anthropicApiKey: process.env.ANTHROPIC_API_KEY,
    anthropicModel: process.env.ANTHROPIC_MODEL ?? 'claude-haiku-4-5-20251001',
  },
});
