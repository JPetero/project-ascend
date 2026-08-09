import { Body, Controller, ForbiddenException, Inject, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AppCapability } from '../../common/entitlements/capability.util';
import { CapabilityService } from '../../common/entitlements/capability.service';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { ResearchQueryDto } from './dto/research-query.dto';
import { RESEARCH_PROVIDER, ResearchProvider } from './providers/research-provider.interface';

/**
 * Research Mode (Build Session 10 Part 16) — gated on
 * `AppCapability.ADVANCED_AI_CONVERSATIONS`, the same Premium capability
 * `free-premium-policy.md` lists it under. The mobile app's
 * `aiProviderProvider` already short-circuits to the local, non-network
 * provider for Free accounts (see companion_chat_controller.dart), but
 * this check is what actually enforces the boundary — a client-side-only
 * gate is never trusted server-side, the same principle VisionController
 * follows.
 */
@ApiBearerAuth()
@ApiTags('research')
@Controller('research')
export class ResearchController {
  constructor(
    private readonly capabilityService: CapabilityService,
    @Inject(RESEARCH_PROVIDER) private readonly provider: ResearchProvider,
  ) {}

  @Post('query')
  async query(@CurrentUser() user: AuthenticatedUser, @Body() dto: ResearchQueryDto) {
    const hasAccess = await this.capabilityService.hasCapabilityForUser(
      user.id,
      AppCapability.ADVANCED_AI_CONVERSATIONS,
    );
    if (!hasAccess) {
      throw new ForbiddenException('Research mode requires Premium.');
    }
    return this.provider.search(dto.query);
  }
}
