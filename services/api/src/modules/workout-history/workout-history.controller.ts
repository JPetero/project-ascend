import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { QueryWorkoutHistoryDto } from './dto/query-workout-history.dto';
import { WorkoutHistoryService } from './workout-history.service';

@ApiBearerAuth()
@ApiTags('workout-history')
@Controller('workout-history')
export class WorkoutHistoryController {
  constructor(private readonly workoutHistoryService: WorkoutHistoryService) {}

  @Get()
  list(@CurrentUser() user: AuthenticatedUser, @Query() query: QueryWorkoutHistoryDto) {
    return this.workoutHistoryService.list(user.id, query);
  }

  @Get('streak')
  streak(@CurrentUser() user: AuthenticatedUser) {
    return this.workoutHistoryService.streak(user.id);
  }

  @Get(':id')
  getById(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.workoutHistoryService.getById(user.id, id);
  }
}
