import { Module } from '@nestjs/common';
import { ExerciseCategoriesController } from './exercise-categories.controller';
import { ExerciseCategoriesService } from './exercise-categories.service';

@Module({
  controllers: [ExerciseCategoriesController],
  providers: [ExerciseCategoriesService],
  exports: [ExerciseCategoriesService],
})
export class ExerciseCategoriesModule {}
