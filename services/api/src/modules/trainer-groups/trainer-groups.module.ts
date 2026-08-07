import { Module } from '@nestjs/common';
import { TrainerGroupsController } from './trainer-groups.controller';
import { TrainerGroupsService } from './trainer-groups.service';

@Module({
  controllers: [TrainerGroupsController],
  providers: [TrainerGroupsService],
  exports: [TrainerGroupsService],
})
export class TrainerGroupsModule {}
