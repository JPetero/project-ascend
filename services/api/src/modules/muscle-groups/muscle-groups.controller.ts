import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { MuscleGroupsService } from './muscle-groups.service';

@ApiBearerAuth()
@ApiTags('muscle-groups')
@Controller('muscle-groups')
export class MuscleGroupsController {
  constructor(private readonly muscleGroupsService: MuscleGroupsService) {}

  @Get()
  list() {
    return this.muscleGroupsService.list();
  }
}
