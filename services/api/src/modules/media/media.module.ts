import { Module } from '@nestjs/common';
import { MediaCleanupService } from './media-cleanup.service';
import { MediaController } from './media.controller';
import { MediaService } from './media.service';
import { MediaStorageModule } from './storage/media-storage.module';

@Module({
  imports: [MediaStorageModule],
  controllers: [MediaController],
  providers: [MediaService, MediaCleanupService],
  exports: [MediaService, MediaCleanupService],
})
export class MediaModule {}
