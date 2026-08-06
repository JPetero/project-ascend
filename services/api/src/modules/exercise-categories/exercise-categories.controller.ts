import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { ExerciseCategoriesService } from './exercise-categories.service';

@ApiBearerAuth()
@ApiTags('exercise-categories')
@Controller('exercise-categories')
export class ExerciseCategoriesController {
  constructor(private readonly exerciseCategoriesService: ExerciseCategoriesService) {}

  @Get()
  list() {
    return this.exerciseCategoriesService.list();
  }
}
