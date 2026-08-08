import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AssistantController } from './assistant.controller';
import { AssistantService } from './assistant.service';

/**
 * Build Session 9 Part 15/16 — the first backend AI provider (see
 * AssistantService's doc comment). Deliberately not exported for other
 * modules to inject: the mobile app is the only caller, via
 * `POST /assistant/reply`.
 */
@Module({
  imports: [ConfigModule],
  controllers: [AssistantController],
  providers: [AssistantService],
})
export class AssistantModule {}
