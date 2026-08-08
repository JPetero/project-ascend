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
import { InviteTrainerGroupMemberDto } from './dto/invite-trainer-group-member.dto';
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
}
