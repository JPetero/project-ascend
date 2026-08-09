import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { TrainerGroupsController } from './trainer-groups.controller';
import { TrainerGroupsService } from './trainer-groups.service';

@Module({
  imports: [NotificationsModule],
  controllers: [TrainerGroupsController],
  providers: [TrainerGroupsService],
  exports: [TrainerGroupsService],
})
export class TrainerGroupsModule {}
