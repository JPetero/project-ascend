import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AiConfig } from '../../config/configuration';
import { AssistantController } from './assistant.controller';
import { AssistantSafetyService } from './assistant-safety.service';
import { AssistantService } from './assistant.service';
import { CompanionMemoryService } from './companion-memory.service';
import { MemoryExtractionService } from './memory-extraction.service';
import { AnthropicReplyProvider } from './providers/anthropic-reply-provider';
import { AI_REPLY_PROVIDER } from './providers/ai-reply-provider.interface';
import { GeminiReplyProvider } from './providers/gemini-reply-provider';
import { OpenAiReplyProvider } from './providers/openai-reply-provider';

/**
 * Build Session 9 Part 15/16 built the first backend AI provider
 * (Anthropic); Build Session 10 Part 14 added Openai/Gemini as
 * alternatives. Selects the active `AiReplyProvider` from `ai.provider`
 * (`AI_PROVIDER` env, default `'anthropic'`) — the same config-driven-
 * factory pattern MediaStorageModule/NotificationsModule use. Every
 * adapter is still constructed (each is cheap — no network call happens
 * until `generateReply` runs), so switching providers is just an env
 * change, never a code change. Deliberately not exported for other
 * modules to inject: the mobile app is the only caller, via
 * `POST /assistant/reply`.
 *
 * Build Session 11 Parts 1-2 added `AssistantSafetyService` (pre/post-
 * provider content classification, registered here) and
 * `AiEntitlementService` (Premium gating for the live-provider path,
 * registered on the global `EntitlementsModule` since `ResearchModule`
 * needs it too — see that module's doc comment). `CapabilityService`/
 * `AiEntitlementService`/`PrismaService` all come from global modules,
 * so nothing else needs importing here.
 */
@Module({
  imports: [ConfigModule],
  controllers: [AssistantController],
  providers: [
    AssistantService,
    AssistantSafetyService,
    CompanionMemoryService,
    MemoryExtractionService,
    AnthropicReplyProvider,
    OpenAiReplyProvider,
    GeminiReplyProvider,
    {
      provide: AI_REPLY_PROVIDER,
      useFactory: (
        configService: ConfigService,
        anthropic: AnthropicReplyProvider,
        openai: OpenAiReplyProvider,
        gemini: GeminiReplyProvider,
      ) => {
        switch (configService.get<AiConfig>('ai')!.provider) {
          case 'openai':
            return openai;
          case 'gemini':
            return gemini;
          default:
            return anthropic;
        }
      },
      inject: [ConfigService, AnthropicReplyProvider, OpenAiReplyProvider, GeminiReplyProvider],
    },
  ],
})
export class AssistantModule {}
