import { Body, Controller, Get, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { AuthIdentitiesService } from './auth-identities.service';
import { LinkIdentityDto } from './dto/link-identity.dto';
import { AppleTokenVerifier } from './providers/apple-token-verifier';
import { GoogleTokenVerifier } from './providers/google-token-verifier';

const LINK_THROTTLE = { default: { limit: 10, ttl: 60_000 } };

/**
 * `POST /link` (Build Session 9 Part 8) verifies the raw provider ID
 * token server-side before ever touching `linkIdentity` — never trusts
 * a client-supplied `providerSubject`, exactly per this file's original
 * doc comment. Requires the caller to already be authenticated, so
 * linking always happens as an explicit action from a signed-in user,
 * never inferred from an email match alone.
 */
@ApiBearerAuth()
@ApiTags('auth-identities')
@Controller('auth-identities')
export class AuthIdentitiesController {
  constructor(
    private readonly authIdentitiesService: AuthIdentitiesService,
    private readonly googleTokenVerifier: GoogleTokenVerifier,
    private readonly appleTokenVerifier: AppleTokenVerifier,
  ) {}

  @Get('me')
  listMine(@CurrentUser() user: AuthenticatedUser) {
    return this.authIdentitiesService.listForUser(user.id);
  }

  @Throttle(LINK_THROTTLE)
  @Post('link')
  async link(@CurrentUser() user: AuthenticatedUser, @Body() dto: LinkIdentityDto) {
    const verifier = dto.provider === 'GOOGLE' ? this.googleTokenVerifier : this.appleTokenVerifier;
    const identity = await verifier.verify(dto.idToken);
    return this.authIdentitiesService.linkIdentity(
      user.id,
      dto.provider,
      identity.subject,
      identity.email ?? undefined,
    );
  }
}
