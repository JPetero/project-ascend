import { Module } from '@nestjs/common';
import { NutritionLibraryController } from './nutrition-library.controller';
import { NutritionLibraryService } from './nutrition-library.service';

@Module({
  controllers: [NutritionLibraryController],
  providers: [NutritionLibraryService],
  exports: [NutritionLibraryService],
})
export class NutritionLibraryModule {}
