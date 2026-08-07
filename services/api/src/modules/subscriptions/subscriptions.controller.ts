import { Body, Controller, Get, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { ApplyEligibilityDto } from './dto/apply-eligibility.dto';
import { SubscriptionsService } from './subscriptions.service';

@ApiBearerAuth()
@ApiTags('subscriptions')
@Controller('subscriptions')
export class SubscriptionsController {
  constructor(private readonly subscriptionsService: SubscriptionsService) {}

  // Registered ahead of nothing param-shaped in this controller, but kept
  // as a static segment for consistency with the rest of the app's route-
  // ordering discipline.
  @Get('pricing')
  getPricing() {
    return this.subscriptionsService.getPricing();
  }

  @Get('me')
  getMyStatus(@CurrentUser() user: AuthenticatedUser) {
    return this.subscriptionsService.getMyStatus(user.id);
  }

  @Get('eligibility')
  getMyEligibility(@CurrentUser() user: AuthenticatedUser) {
    return this.subscriptionsService.getMyEligibility(user.id);
  }

  @Post('eligibility')
  applyForEligibility(@CurrentUser() user: AuthenticatedUser, @Body() dto: ApplyEligibilityDto) {
    return this.subscriptionsService.applyForEligibility(user.id, dto);
  }
}
