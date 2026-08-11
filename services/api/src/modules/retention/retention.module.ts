import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { RetentionService } from './retention.service';

@Module({
  imports: [NotificationsModule],
  providers: [RetentionService],
  exports: [RetentionService],
})
export class RetentionModule {}
