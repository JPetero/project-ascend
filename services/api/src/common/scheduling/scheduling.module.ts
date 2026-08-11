import { Global, Module } from '@nestjs/common';
import { SchedulerLockService } from './scheduler-lock.service';

/**
 * Global, like PrismaModule — every `@Cron` job (RetentionService,
 * MediaCleanupService, SecurityTokenCleanupService, and any future
 * one) needs `SchedulerLockService`, so it's registered once here
 * rather than every feature module re-importing it.
 */
@Global()
@Module({
  providers: [SchedulerLockService],
  exports: [SchedulerLockService],
})
export class SchedulingModule {}
