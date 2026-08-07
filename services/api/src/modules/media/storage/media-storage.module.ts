import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { LocalDevelopmentStorageProvider } from './local-development-storage.provider';
import { MEDIA_STORAGE_PROVIDER } from './media-storage.provider';
import { S3CompatibleStorageProvider } from './s3-compatible-storage.provider';

/**
 * Selects the active `MediaStorageProvider` from
 * `MEDIA_STORAGE_PROVIDER` ('local' | 's3'), defaulting to the local
 * adapter — which is also what every test in this repository runs
 * against, since no S3 credentials exist in this environment.
 */
@Module({
  imports: [ConfigModule],
  providers: [
    LocalDevelopmentStorageProvider,
    S3CompatibleStorageProvider,
    {
      provide: MEDIA_STORAGE_PROVIDER,
      useFactory: (
        configService: ConfigService,
        local: LocalDevelopmentStorageProvider,
        s3: S3CompatibleStorageProvider,
      ) => (configService.get<string>('media.storageProvider') === 's3' ? s3 : local),
      inject: [ConfigService, LocalDevelopmentStorageProvider, S3CompatibleStorageProvider],
    },
  ],
  exports: [MEDIA_STORAGE_PROVIDER, LocalDevelopmentStorageProvider],
})
export class MediaStorageModule {}
