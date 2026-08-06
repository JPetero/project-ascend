import { Body, Controller, Delete, Get, Param, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { CreateWorkoutPlanDto } from './dto/create-workout-plan.dto';
import { UpdateWorkoutPlanDto } from './dto/update-workout-plan.dto';
import { WorkoutPlansService } from './workout-plans.service';

@ApiBearerAuth()
@ApiTags('workout-plans')
@Controller('workout-plans')
export class WorkoutPlansController {
  constructor(private readonly workoutPlansService: WorkoutPlansService) {}

  @Get()
  list(@CurrentUser() user: AuthenticatedUser) {
    return this.workoutPlansService.list(user.id);
  }

  @Get(':id')
  getById(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.workoutPlansService.getById(user.id, id);
  }

  @Post()
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateWorkoutPlanDto) {
    return this.workoutPlansService.create(user.id, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: UpdateWorkoutPlanDto,
  ) {
    return this.workoutPlansService.update(user.id, id, dto);
  }

  @Delete(':id')
  async remove(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.workoutPlansService.remove(user.id, id);
    return { deleted: true };
  }
}
