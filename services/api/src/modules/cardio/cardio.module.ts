import { Module } from '@nestjs/common';
import { AchievementsModule } from '../achievements/achievements.module';
import { CardioController } from './cardio.controller';
import { CardioService } from './cardio.service';

@Module({
  imports: [AchievementsModule],
  controllers: [CardioController],
  providers: [CardioService],
  exports: [CardioService],
})
export class CardioModule {}
