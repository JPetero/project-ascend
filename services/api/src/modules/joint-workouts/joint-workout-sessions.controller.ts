import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { CreateJointWorkoutSessionDto } from './dto/create-joint-workout-session.dto';
import { InviteToJointWorkoutSessionDto } from './dto/invite-to-joint-workout-session.dto';
import { SubmitJointWorkoutProgressDto } from './dto/submit-joint-workout-progress.dto';
import { JointWorkoutSessionsService } from './joint-workout-sessions.service';

@ApiBearerAuth()
@ApiTags('joint-workouts')
@Controller('joint-workouts')
export class JointWorkoutSessionsController {
  constructor(private readonly sessions: JointWorkoutSessionsService) {}

  @Get()
  listMine(@CurrentUser() user: AuthenticatedUser) {
    return this.sessions.listMine(user.id);
  }

  @Post()
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateJointWorkoutSessionDto) {
    return this.sessions.create(user.id, dto);
  }

  @Get(':id')
  getById(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.sessions.getById(user.id, id);
  }

  @Post(':id/invite')
  invite(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: InviteToJointWorkoutSessionDto,
  ) {
    return this.sessions.invite(user.id, id, dto.inviteeId);
  }

  @Post(':id/accept')
  accept(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.sessions.acceptInvite(user.id, id);
  }

  @Post(':id/decline')
  decline(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.sessions.declineInvite(user.id, id);
  }

  @Post(':id/ready')
  ready(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.sessions.markReady(user.id, id);
  }

  @Post(':id/start')
  start(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.sessions.start(user.id, id);
  }

  @Post(':id/progress')
  progress(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: SubmitJointWorkoutProgressDto,
  ) {
    return this.sessions.submitProgress(user.id, id, dto);
  }

  @Post(':id/finish')
  finish(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.sessions.finish(user.id, id);
  }

  @Post(':id/leave')
  async leave(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.sessions.leave(user.id, id);
    return { left: true };
  }

  @Post(':id/cancel')
  async cancel(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.sessions.cancel(user.id, id);
    return { canceled: true };
  }
}
