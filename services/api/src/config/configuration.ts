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

export default (): { app: AppConfig; media: MediaConfig } => ({
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
});
