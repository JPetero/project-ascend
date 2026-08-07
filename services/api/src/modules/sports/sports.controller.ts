import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { SportCode } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { CreateSportMatchDto } from './dto/create-sport-match.dto';
import { DisputeScoreDto } from './dto/dispute-score.dto';
import { ProposeScoreDto } from './dto/propose-score.dto';
import { SportsService } from './sports.service';

@ApiBearerAuth()
@ApiTags('sports')
@Controller('sports')
export class SportsController {
  constructor(private readonly sports: SportsService) {}

  @Get()
  listSports() {
    return this.sports.listSports();
  }

  @Get('matches')
  listMine(@CurrentUser() user: AuthenticatedUser) {
    return this.sports.listMine(user.id);
  }

  @Post('matches')
  createMatch(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateSportMatchDto) {
    return this.sports.createMatch(user.id, dto);
  }

  @Get('matches/:id')
  getById(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.sports.getById(user.id, id);
  }

  @Post('matches/:id/accept')
  accept(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.sports.acceptInvite(user.id, id);
  }

  @Post('matches/:id/decline')
  decline(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.sports.declineInvite(user.id, id);
  }

  @Post('matches/:id/ready')
  ready(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.sports.markReady(user.id, id);
  }

  @Post('matches/:id/start')
  start(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.sports.start(user.id, id);
  }

  @Post('matches/:id/score')
  proposeScore(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: ProposeScoreDto,
  ) {
    return this.sports.proposeScore(user.id, id, dto);
  }

  @Post('matches/:id/score/confirm')
  confirmScore(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.sports.confirmScore(user.id, id);
  }

  @Post('matches/:id/score/dispute')
  disputeScore(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: DisputeScoreDto,
  ) {
    return this.sports.disputeScore(user.id, id, dto.reason);
  }

  @Post('matches/:id/cancel')
  cancel(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.sports.cancel(user.id, id);
  }

  @Post('matches/:id/void')
  voidMatch(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.sports.voidMatch(user.id, id);
  }

  @Get(':sportCode/rating')
  getMyRating(@CurrentUser() user: AuthenticatedUser, @Param('sportCode') sportCode: SportCode) {
    return this.sports.getMyRating(user.id, sportCode);
  }

  @Get(':sportCode/leaderboard')
  leaderboard(@Param('sportCode') sportCode: SportCode, @Query('limit') limit?: string) {
    return this.sports.leaderboard(sportCode, limit ? Number(limit) : undefined);
  }
}
