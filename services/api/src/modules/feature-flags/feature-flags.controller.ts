import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { FeatureFlagsService } from './feature-flags.service';

/**
 * Client-facing resolution endpoint — every signed-in user calls this to
 * get their own resolved flag map. Admin CRUD over the underlying
 * FeatureFlag rows lives on AdminController (MANAGE_PLATFORM), not here.
 */
@ApiBearerAuth()
@ApiTags('feature-flags')
@Controller('feature-flags')
export class FeatureFlagsController {
  constructor(private readonly featureFlagsService: FeatureFlagsService) {}

  @Get()
  resolve(@CurrentUser() user: AuthenticatedUser) {
    return this.featureFlagsService.resolveForUser(user.id);
  }
}
