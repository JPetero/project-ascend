import { Module } from '@nestjs/common';
import { WorkoutHistoryController } from './workout-history.controller';
import { WorkoutHistoryService } from './workout-history.service';

@Module({
  controllers: [WorkoutHistoryController],
  providers: [WorkoutHistoryService],
  exports: [WorkoutHistoryService],
})
export class WorkoutHistoryModule {}
