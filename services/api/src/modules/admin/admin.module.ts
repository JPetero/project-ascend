import { Module } from '@nestjs/common';
import { FeatureFlagsModule } from '../feature-flags/feature-flags.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { ReleaseReadinessService } from './release-readiness.service';

@Module({
  imports: [NotificationsModule, FeatureFlagsModule],
  controllers: [AdminController],
  providers: [AdminService, ReleaseReadinessService],
})
export class AdminModule {}
