import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AssistantController } from './assistant.controller';
import { AiProviderCircuitBreaker } from './ai-provider-circuit-breaker.service';
import { AiReplyProviderRouter } from './ai-reply-provider-router';
import { AiUsagePolicy } from './ai-usage-policy.service';
import { AssistantSafetyService } from './assistant-safety.service';
import { AssistantService } from './assistant.service';
import { CompanionConversationsService } from './companion-conversations.service';
import { CompanionMemoryService } from './companion-memory.service';
import { MemoryExtractionService } from './memory-extraction.service';
import { AnthropicReplyProvider } from './providers/anthropic-reply-provider';
import { AI_REPLY_PROVIDER } from './providers/ai-reply-provider.interface';
import { GeminiReplyProvider } from './providers/gemini-reply-provider';
import { OpenAiReplyProvider } from './providers/openai-reply-provider';

/**
 * Build Session 9 Part 15/16 built the first backend AI provider
 * (Anthropic); Build Session 10 Part 14 added Openai/Gemini as
 * alternatives. Build Session 12 Part 6 replaced the single-provider
 * factory with `AiReplyProviderRouter` — `AI_REPLY_PROVIDER` now
 * resolves to the router, which tries the configured preferred provider
 * first and falls back sequentially to the others if it's unconfigured/
 * unhealthy/erroring, instead of a single provider's failure always
 * failing the whole request. Every adapter is still constructed (each is
 * cheap — no network call happens until `generateReply` runs), so which
 * one is "preferred" stays an env change, never a code change.
 * Deliberately not exported for other modules to inject: the mobile app
 * is the only caller, via `POST /assistant/reply`.
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
    CompanionConversationsService,
    MemoryExtractionService,
    AiProviderCircuitBreaker,
    AiUsagePolicy,
    AiReplyProviderRouter,
    AnthropicReplyProvider,
    OpenAiReplyProvider,
    GeminiReplyProvider,
    {
      provide: AI_REPLY_PROVIDER,
      useExisting: AiReplyProviderRouter,
    },
  ],
})
export class AssistantModule {}
