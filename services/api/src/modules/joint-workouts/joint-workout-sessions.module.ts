import { Module } from '@nestjs/common';
import { FriendsModule } from '../friends/friends.module';
import { TrainerGroupsModule } from '../trainer-groups/trainer-groups.module';
import { JointWorkoutSessionsController } from './joint-workout-sessions.controller';
import { JointWorkoutSessionsService } from './joint-workout-sessions.service';

@Module({
  imports: [FriendsModule, TrainerGroupsModule],
  controllers: [JointWorkoutSessionsController],
  providers: [JointWorkoutSessionsService],
  exports: [JointWorkoutSessionsService],
})
export class JointWorkoutSessionsModule {}
