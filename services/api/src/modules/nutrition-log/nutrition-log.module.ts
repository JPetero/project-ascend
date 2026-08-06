import { Module } from '@nestjs/common';
import { AchievementsModule } from '../achievements/achievements.module';
import { NutritionLogController } from './nutrition-log.controller';
import { NutritionLogService } from './nutrition-log.service';

@Module({
  imports: [AchievementsModule],
  controllers: [NutritionLogController],
  providers: [NutritionLogService],
  exports: [NutritionLogService],
})
export class NutritionLogModule {}
