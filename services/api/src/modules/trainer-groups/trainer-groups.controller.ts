import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { PaginationQueryDto } from '../../common/pagination/pagination-query.dto';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { CreateTrainerGroupAnnouncementDto } from './dto/create-trainer-group-announcement.dto';
import { CreateTrainerGroupDto } from './dto/create-trainer-group.dto';
import { CreateTrainerGroupScheduledSessionDto } from './dto/create-trainer-group-scheduled-session.dto';
import { CreateWorkoutAssignmentDto } from './dto/create-workout-assignment.dto';
import { InviteTrainerGroupMemberDto } from './dto/invite-trainer-group-member.dto';
import { RsvpScheduledSessionDto } from './dto/rsvp-scheduled-session.dto';
import { SendTrainerGroupMessageDto } from './dto/send-trainer-group-message.dto';
import { SetTrainerGroupMemberRoleDto } from './dto/set-trainer-group-member-role.dto';
import { ShareTrainerGroupPlanDto } from './dto/share-trainer-group-plan.dto';
import { TrainerGroupsService } from './trainer-groups.service';

@ApiBearerAuth()
@ApiTags('trainer-groups')
@Controller('trainer-groups')
export class TrainerGroupsController {
  constructor(private readonly trainerGroupsService: TrainerGroupsService) {}

  @Post()
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateTrainerGroupDto) {
    return this.trainerGroupsService.createGroup(user.id, dto);
  }

  @Get()
  listMine(@CurrentUser() user: AuthenticatedUser) {
    return this.trainerGroupsService.listMyGroups(user.id);
  }

  // Registered ahead of GET /:id so "invitations" is never mistaken for
  // a group id.
  @Get('invitations')
  listMyInvitations(@CurrentUser() user: AuthenticatedUser) {
    return this.trainerGroupsService.listMyInvitations(user.id);
  }

  @Post('invitations/:invitationId/accept')
  acceptInvitation(
    @CurrentUser() user: AuthenticatedUser,
    @Param('invitationId') invitationId: string,
  ) {
    return this.trainerGroupsService.respondToInvitation(user.id, invitationId, true);
  }

  @Post('invitations/:invitationId/decline')
  declineInvitation(
    @CurrentUser() user: AuthenticatedUser,
    @Param('invitationId') invitationId: string,
  ) {
    return this.trainerGroupsService.respondToInvitation(user.id, invitationId, false);
  }

  @Delete('invitations/:invitationId')
  @HttpCode(HttpStatus.NO_CONTENT)
  cancelInvitation(
    @CurrentUser() user: AuthenticatedUser,
    @Param('invitationId') invitationId: string,
  ) {
    return this.trainerGroupsService.cancelInvitation(user.id, invitationId);
  }

  // Registered ahead of GET/DELETE /:id for the same reason
  // "invitations" is — "dashboard", "assignments" and
  // "scheduled-sessions" must never be mistaken for a group id.
  @Get('dashboard')
  getTrainerDashboard(@CurrentUser() user: AuthenticatedUser) {
    return this.trainerGroupsService.getTrainerDashboard(user.id);
  }

  @Get('assignments/mine')
  listMyAssignments(@CurrentUser() user: AuthenticatedUser) {
    return this.trainerGroupsService.listMyAssignments(user.id);
  }

  @Post('assignments/:assignmentId/accept')
  acceptAssignment(
    @CurrentUser() user: AuthenticatedUser,
    @Param('assignmentId') assignmentId: string,
  ) {
    return this.trainerGroupsService.acceptAssignment(user.id, assignmentId);
  }

  @Post('assignments/:assignmentId/decline')
  declineAssignment(
    @CurrentUser() user: AuthenticatedUser,
    @Param('assignmentId') assignmentId: string,
  ) {
    return this.trainerGroupsService.declineAssignment(user.id, assignmentId);
  }

  @Delete('assignments/:assignmentId')
  @HttpCode(HttpStatus.NO_CONTENT)
  cancelAssignment(
    @CurrentUser() user: AuthenticatedUser,
    @Param('assignmentId') assignmentId: string,
  ) {
    return this.trainerGroupsService.cancelAssignment(user.id, assignmentId);
  }

  @Delete('scheduled-sessions/:sessionId')
  @HttpCode(HttpStatus.NO_CONTENT)
  cancelScheduledSession(
    @CurrentUser() user: AuthenticatedUser,
    @Param('sessionId') sessionId: string,
  ) {
    return this.trainerGroupsService.cancelScheduledSession(user.id, sessionId);
  }

  @Post('scheduled-sessions/:sessionId/rsvp')
  rsvpToScheduledSession(
    @CurrentUser() user: AuthenticatedUser,
    @Param('sessionId') sessionId: string,
    @Body() dto: RsvpScheduledSessionDto,
  ) {
    return this.trainerGroupsService.rsvpToScheduledSession(user.id, sessionId, dto.status);
  }

  @Delete('scheduled-sessions/:sessionId/rsvp')
  cancelMyRsvp(@CurrentUser() user: AuthenticatedUser, @Param('sessionId') sessionId: string) {
    return this.trainerGroupsService.cancelMyRsvp(user.id, sessionId);
  }

  @Get(':id')
  getGroup(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.trainerGroupsService.getGroup(user.id, id);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  deleteGroup(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.trainerGroupsService.deleteGroup(user.id, id);
  }

  @Post(':id/invitations')
  invite(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: InviteTrainerGroupMemberDto,
  ) {
    return this.trainerGroupsService.invite(user.id, id, dto);
  }

  @Delete(':id/members/:userId')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeMember(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Param('userId') targetUserId: string,
  ) {
    return this.trainerGroupsService.removeMember(user.id, id, targetUserId);
  }

  @Patch(':id/members/:userId/role')
  setMemberRole(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Param('userId') targetUserId: string,
    @Body() dto: SetTrainerGroupMemberRoleDto,
  ) {
    return this.trainerGroupsService.setMemberRole(user.id, id, targetUserId, dto);
  }

  @Post(':id/announcements')
  postAnnouncement(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: CreateTrainerGroupAnnouncementDto,
  ) {
    return this.trainerGroupsService.postAnnouncement(user.id, id, dto);
  }

  @Get(':id/announcements')
  listAnnouncements(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.trainerGroupsService.listAnnouncements(user.id, id);
  }

  @Post(':id/messages')
  sendMessage(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: SendTrainerGroupMessageDto,
  ) {
    return this.trainerGroupsService.sendMessage(user.id, id, dto);
  }

  @Get(':id/messages')
  listMessages(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Query() query: PaginationQueryDto,
  ) {
    return this.trainerGroupsService.listMessages(user.id, id, query);
  }

  @Post(':id/shared-plans')
  sharePlan(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: ShareTrainerGroupPlanDto,
  ) {
    return this.trainerGroupsService.sharePlan(user.id, id, dto);
  }

  @Get(':id/shared-plans')
  listSharedPlans(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.trainerGroupsService.listSharedPlans(user.id, id);
  }

  @Delete(':id/shared-plans/:sharedPlanId')
  @HttpCode(HttpStatus.NO_CONTENT)
  unsharePlan(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Param('sharedPlanId') sharedPlanId: string,
  ) {
    return this.trainerGroupsService.unsharePlan(user.id, id, sharedPlanId);
  }

  @Post(':id/assignments')
  createAssignments(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: CreateWorkoutAssignmentDto,
  ) {
    return this.trainerGroupsService.createAssignments(user.id, id, dto);
  }

  @Get(':id/assignments')
  listGroupAssignments(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.trainerGroupsService.listGroupAssignments(user.id, id);
  }

  @Post(':id/scheduled-sessions')
  createScheduledSession(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: CreateTrainerGroupScheduledSessionDto,
  ) {
    return this.trainerGroupsService.createScheduledSession(user.id, id, dto);
  }

  @Get(':id/scheduled-sessions')
  listScheduledSessions(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.trainerGroupsService.listScheduledSessions(user.id, id);
  }
}
