import { Module } from '@nestjs/common';
import { VisionController } from './vision.controller';
import { VisionService } from './vision.service';

/**
 * Private Vision analysis-session history (Build Session 10 Part 6).
 * `CapabilityService`/`PrismaService` come from the global
 * `EntitlementsModule`/`PrismaModule`, so nothing else needs importing
 * here.
 */
@Module({
  controllers: [VisionController],
  providers: [VisionService],
})
export class VisionModule {}
