import { Module } from '@nestjs/common';
import { FriendsModule } from '../friends/friends.module';
import { MediaModule } from '../media/media.module';
import { CommunityController } from './community.controller';
import { CommunityService } from './community.service';
import { TrainerVerificationService } from './trainer-verification.service';

@Module({
  imports: [MediaModule, FriendsModule],
  controllers: [CommunityController],
  providers: [CommunityService, TrainerVerificationService],
  exports: [CommunityService],
})
export class CommunityModule {}
