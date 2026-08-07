import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { CreateCampaignDto } from './dto/create-campaign.dto';
import { PromoteService } from './promote.service';

@ApiBearerAuth()
@ApiTags('promote')
@Controller('promote/campaigns')
export class PromoteController {
  constructor(private readonly promoteService: PromoteService) {}

  @Post()
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateCampaignDto) {
    return this.promoteService.createCampaign(user.id, dto);
  }

  @Get()
  listMine(@CurrentUser() user: AuthenticatedUser) {
    return this.promoteService.listMine(user.id);
  }

  @Get(':id/metrics')
  getMetrics(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.promoteService.getMetrics(user.id, id);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  end(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.promoteService.endCampaign(user.id, id);
  }

  @Post(':id/impression')
  @HttpCode(HttpStatus.OK)
  recordImpression(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.promoteService.recordImpression(user.id, id);
  }

  @Post(':id/click')
  @HttpCode(HttpStatus.OK)
  recordClick(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.promoteService.recordClick(user.id, id);
  }
}
