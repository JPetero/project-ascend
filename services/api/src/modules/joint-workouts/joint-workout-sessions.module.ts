import { Module } from '@nestjs/common';
import { FriendsModule } from '../friends/friends.module';
import { JointWorkoutSessionsController } from './joint-workout-sessions.controller';
import { JointWorkoutSessionsService } from './joint-workout-sessions.service';

@Module({
  imports: [FriendsModule],
  controllers: [JointWorkoutSessionsController],
  providers: [JointWorkoutSessionsService],
  exports: [JointWorkoutSessionsService],
})
export class JointWorkoutSessionsModule {}
