import { Module } from '@nestjs/common';
import { MuscleGroupsController } from './muscle-groups.controller';
import { MuscleGroupsService } from './muscle-groups.service';

@Module({
  controllers: [MuscleGroupsController],
  providers: [MuscleGroupsService],
  exports: [MuscleGroupsService],
})
export class MuscleGroupsModule {}
