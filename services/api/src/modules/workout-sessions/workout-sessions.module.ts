import { Module } from '@nestjs/common';
import { AchievementsModule } from '../achievements/achievements.module';
import { PersonalRecordsModule } from '../personal-records/personal-records.module';
import { TrainerGroupsModule } from '../trainer-groups/trainer-groups.module';
import { WorkoutSessionsController } from './workout-sessions.controller';
import { WorkoutSessionsService } from './workout-sessions.service';

@Module({
  imports: [PersonalRecordsModule, AchievementsModule, TrainerGroupsModule],
  controllers: [WorkoutSessionsController],
  providers: [WorkoutSessionsService],
  exports: [WorkoutSessionsService],
})
export class WorkoutSessionsModule {}
