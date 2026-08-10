import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ResearchConfig } from '../../config/configuration';
import { AssistantModule } from '../assistant/assistant.module';
import { ResearchController } from './research.controller';
import { ResearchQueryPlannerService } from './research-query-planner.service';
import { ResearchSynthesisService } from './research-synthesis.service';
import { BraveSearchResearchProvider } from './providers/brave-search-research-provider';
import { NoopResearchProvider } from './providers/noop-research-provider';
import { RESEARCH_PROVIDER } from './providers/research-provider.interface';

/**
 * Selects the active `ResearchProvider` from `research.braveSearchApiKey`
 * (`BRAVE_SEARCH_API_KEY` env) — the same config-driven-factory pattern
 * AssistantModule/NotificationsModule use. Defaults to the Noop adapter,
 * which is also what every test in this repository runs against, since
 * no Brave Search key exists in this environment.
 * `AiEntitlementService`/`CapabilityService`/`PrismaService` come from
 * the global `EntitlementsModule`/`PrismaModule`, so nothing else needs
 * importing here. `AssistantModule` is imported (S13 Part 10-12) so
 * `ResearchSynthesisService` can inject its exported `AI_REPLY_PROVIDER`
 * for optional grounded generative synthesis — see that service's doc
 * comment for the extractive-first, generative-on-top design.
 */
@Module({
  imports: [ConfigModule, AssistantModule],
  controllers: [ResearchController],
  providers: [
    NoopResearchProvider,
    BraveSearchResearchProvider,
    ResearchQueryPlannerService,
    ResearchSynthesisService,
    {
      provide: RESEARCH_PROVIDER,
      useFactory: (
        configService: ConfigService,
        noop: NoopResearchProvider,
        brave: BraveSearchResearchProvider,
      ) => {
        const research = configService.get<ResearchConfig>('research');
        return research?.braveSearchApiKey ? brave : noop;
      },
      inject: [ConfigService, NoopResearchProvider, BraveSearchResearchProvider],
    },
  ],
})
export class ResearchModule {}
