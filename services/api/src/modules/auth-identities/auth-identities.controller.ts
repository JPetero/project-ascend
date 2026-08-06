import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { AuthIdentitiesService } from './auth-identities.service';

/**
 * Read-only for now. `AuthIdentitiesService.linkIdentity` exists as the
 * architecture Scenario 2/3 needs, but a POST /link endpoint isn't exposed
 * here yet — accepting a client-supplied providerSubject without verifying
 * it against the provider's own token first would let a caller claim any
 * identity. That verification step ships alongside real Google/Apple
 * OAuth credentials (see packages/docs/product/parking-lot.md).
 */
@ApiBearerAuth()
@ApiTags('auth-identities')
@Controller('auth-identities')
export class AuthIdentitiesController {
  constructor(private readonly authIdentitiesService: AuthIdentitiesService) {}

  @Get('me')
  listMine(@CurrentUser() user: AuthenticatedUser) {
    return this.authIdentitiesService.listForUser(user.id);
  }
}
