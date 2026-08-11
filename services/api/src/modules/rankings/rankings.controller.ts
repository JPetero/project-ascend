import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { OptInRankingsDto } from './dto/opt-in-rankings.dto';
import { QueryLeaderboardDto } from './dto/query-leaderboard.dto';
import { RankingsService } from './rankings.service';

@ApiBearerAuth()
@ApiTags('rankings')
@Controller('rankings')
export class RankingsController {
  constructor(private readonly rankingsService: RankingsService) {}

  @Put('opt-in')
  optIn(@CurrentUser() user: AuthenticatedUser, @Body() dto: OptInRankingsDto) {
    return this.rankingsService.optIn(user.id, dto);
  }

  @Delete('opt-in')
  @HttpCode(HttpStatus.NO_CONTENT)
  optOut(@CurrentUser() user: AuthenticatedUser) {
    return this.rankingsService.optOut(user.id);
  }

  @Get('me')
  getMyStatus(@CurrentUser() user: AuthenticatedUser) {
    return this.rankingsService.getMyStatus(user.id);
  }

  @Get('leaderboard')
  getLeaderboard(@CurrentUser() user: AuthenticatedUser, @Query() query: QueryLeaderboardDto) {
    return this.rankingsService.getLeaderboard(
      user.id,
      query.scope,
      query.page,
      query.limit,
      query.category,
    );
  }
}
