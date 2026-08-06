import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { FinishWorkoutSessionDto } from './dto/finish-workout-session.dto';
import { LogSetDto } from './dto/log-set.dto';
import { StartWorkoutSessionDto } from './dto/start-workout-session.dto';
import { SubstituteExerciseDto } from './dto/substitute-exercise.dto';
import { UpdateSetDto } from './dto/update-set.dto';
import { WorkoutSessionsService } from './workout-sessions.service';

@ApiBearerAuth()
@ApiTags('workout-sessions')
@Controller('workout-sessions')
export class WorkoutSessionsController {
  constructor(private readonly workoutSessionsService: WorkoutSessionsService) {}

  @Post()
  start(@CurrentUser() user: AuthenticatedUser, @Body() dto: StartWorkoutSessionDto) {
    return this.workoutSessionsService.start(user.id, dto);
  }

  @Get('active')
  getActive(@CurrentUser() user: AuthenticatedUser) {
    return this.workoutSessionsService.getActive(user.id);
  }

  @Get(':id')
  getById(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.workoutSessionsService.getById(user.id, id);
  }

  @Post(':id/pause')
  @HttpCode(HttpStatus.OK)
  pause(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.workoutSessionsService.pause(user.id, id);
  }

  @Post(':id/resume')
  @HttpCode(HttpStatus.OK)
  resume(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.workoutSessionsService.resume(user.id, id);
  }

  @Post(':id/finish')
  @HttpCode(HttpStatus.OK)
  finish(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: FinishWorkoutSessionDto,
  ) {
    return this.workoutSessionsService.finish(user.id, id, dto);
  }

  @Post(':id/abandon')
  @HttpCode(HttpStatus.OK)
  abandon(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.workoutSessionsService.abandon(user.id, id);
  }

  @Post(':id/sets')
  logSet(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string, @Body() dto: LogSetDto) {
    return this.workoutSessionsService.logSet(user.id, id, dto);
  }

  @Post(':id/substitutions')
  @HttpCode(HttpStatus.OK)
  substituteExercise(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: SubstituteExerciseDto,
  ) {
    return this.workoutSessionsService.substituteExercise(user.id, id, dto);
  }

  @Patch(':id/sets/:setId')
  updateSet(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Param('setId') setId: string,
    @Body() dto: UpdateSetDto,
  ) {
    return this.workoutSessionsService.updateSet(user.id, id, setId, dto);
  }

  @Delete(':id/sets/:setId')
  async removeSet(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Param('setId') setId: string,
  ) {
    await this.workoutSessionsService.removeSet(user.id, id, setId);
    return { deleted: true };
  }
}
