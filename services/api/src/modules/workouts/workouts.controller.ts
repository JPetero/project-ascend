import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { QueryWorkoutsDto } from './dto/query-workouts.dto';
import { WorkoutsService } from './workouts.service';

@ApiBearerAuth()
@ApiTags('workouts')
@Controller('workouts')
export class WorkoutsController {
  constructor(private readonly workoutsService: WorkoutsService) {}

  @Get()
  list(@Query() query: QueryWorkoutsDto) {
    return this.workoutsService.list(query);
  }

  @Get(':id')
  getById(@Param('id') id: string) {
    return this.workoutsService.getById(id);
  }
}
