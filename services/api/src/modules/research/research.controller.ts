import { Body, Controller, ForbiddenException, Inject, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AiEntitlementService } from '../../common/entitlements/ai-entitlement.service';
import { AiFeature } from '../../common/entitlements/ai-entitlement.types';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { ResearchQueryDto } from './dto/research-query.dto';
import { RESEARCH_PROVIDER, ResearchProvider } from './providers/research-provider.interface';

/**
 * Research Mode (Build Session 10 Part 16) — gated on
 * `AiFeature.RESEARCH` (resolves to `AppCapability.ADVANCED_AI_CONVERSATIONS`,
 * the same Premium capability `free-premium-policy.md` lists it under).
 * Build Session 11 Part 1 moved this off a raw inline `CapabilityService`
 * check and onto the shared `AiEntitlementService` every AI-adjacent
 * endpoint now goes through, so a future change to how AI features are
 * gated (e.g. Research getting its own SKU) is a one-line change in one
 * place. The mobile app's `aiProviderProvider` already short-circuits to
 * the local, non-network provider for Free accounts (see
 * companion_chat_controller.dart), but this check is what actually
 * enforces the boundary — a client-side-only gate is never trusted
 * server-side, the same principle VisionController follows.
 */
@ApiBearerAuth()
@ApiTags('research')
@Controller('research')
export class ResearchController {
  constructor(
    private readonly entitlement: AiEntitlementService,
    @Inject(RESEARCH_PROVIDER) private readonly provider: ResearchProvider,
  ) {}

  @Post('query')
  async query(@CurrentUser() user: AuthenticatedUser, @Body() dto: ResearchQueryDto) {
    const access = await this.entitlement.checkAccess(user.id, AiFeature.RESEARCH);
    if (!access.allowed) {
      throw new ForbiddenException(access.reason ?? 'Research mode requires Premium.');
    }
    return this.provider.search(dto.query);
  }
}
