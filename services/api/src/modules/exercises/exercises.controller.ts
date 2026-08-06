import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { QueryExercisesDto } from './dto/query-exercises.dto';
import { ExercisesService } from './exercises.service';

@ApiBearerAuth()
@ApiTags('exercises')
@Controller('exercises')
export class ExercisesController {
  constructor(private readonly exercisesService: ExercisesService) {}

  @Get()
  list(@Query() query: QueryExercisesDto) {
    return this.exercisesService.list(query);
  }

  @Get(':id')
  getById(@Param('id') id: string) {
    return this.exercisesService.getById(id);
  }

  @Get(':id/progression')
  getProgression(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.exercisesService.getProgressionSuggestion(user.id, id);
  }
}
