import { Module } from '@nestjs/common';
import { FriendsModule } from '../friends/friends.module';
import { MediaModule } from '../media/media.module';
import { CommunityController } from './community.controller';
import { CommunityService } from './community.service';

@Module({
  imports: [MediaModule, FriendsModule],
  controllers: [CommunityController],
  providers: [CommunityService],
  exports: [CommunityService],
})
export class CommunityModule {}
