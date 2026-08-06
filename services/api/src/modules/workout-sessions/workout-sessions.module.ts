import { Module } from '@nestjs/common';
import { PersonalRecordsModule } from '../personal-records/personal-records.module';
import { WorkoutSessionsController } from './workout-sessions.controller';
import { WorkoutSessionsService } from './workout-sessions.service';

@Module({
  imports: [PersonalRecordsModule],
  controllers: [WorkoutSessionsController],
  providers: [WorkoutSessionsService],
  exports: [WorkoutSessionsService],
})
export class WorkoutSessionsModule {}
