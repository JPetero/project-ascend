import { Module } from '@nestjs/common';
import { NutritionLogModule } from '../nutrition-log/nutrition-log.module';
import { SavedMealsController } from './saved-meals.controller';
import { SavedMealsService } from './saved-meals.service';

@Module({
  imports: [NutritionLogModule],
  controllers: [SavedMealsController],
  providers: [SavedMealsService],
})
export class SavedMealsModule {}
