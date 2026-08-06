import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { DeloadService } from './deload.service';
import { PostponeDeloadDto } from './dto/postpone-deload.dto';

@ApiBearerAuth()
@ApiTags('deload')
@Controller('deload')
export class DeloadController {
  constructor(private readonly deloadService: DeloadService) {}

  @Get('recommendation')
  getActive(@CurrentUser() user: AuthenticatedUser) {
    return this.deloadService.getActiveRecommendation(user.id);
  }

  @Post('recommendations/:id/dismiss')
  dismiss(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.deloadService.dismiss(user.id, id);
  }

  @Post('recommendations/:id/postpone')
  postpone(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: PostponeDeloadDto,
  ) {
    return this.deloadService.postpone(user.id, id, dto.days ?? 7);
  }
}
