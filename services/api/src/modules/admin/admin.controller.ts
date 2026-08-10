import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseEnumPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AdminPermission } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequireAdminPermission } from '../../common/decorators/require-admin-permission.decorator';
import { AdminPermissionGuard } from '../../common/guards/admin-permission.guard';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { UpsertFeatureFlagDto } from '../feature-flags/dto/upsert-feature-flag.dto';
import { FeatureFlagsService } from '../feature-flags/feature-flags.service';
import { AdminService } from './admin.service';
import { ActionReportDto } from './dto/action-report.dto';
import { DecideCampaignDto } from './dto/decide-campaign.dto';
import { DecideEligibilityDto } from './dto/decide-eligibility.dto';
import { GrantAdminPermissionDto } from './dto/grant-admin-permission.dto';
import { ListCampaignsDto } from './dto/list-campaigns.dto';
import { ListEligibilityDto } from './dto/list-eligibility.dto';
import { ListReportsDto } from './dto/list-reports.dto';
import { ListTicketsDto } from './dto/list-tickets.dto';
import { AdminReplyTicketDto } from './dto/reply-ticket.dto';
import { ReleaseReadinessService } from './release-readiness.service';

@ApiBearerAuth()
@ApiTags('admin')
@UseGuards(AdminPermissionGuard)
@Controller('admin')
export class AdminController {
  constructor(
    private readonly adminService: AdminService,
    private readonly featureFlagsService: FeatureFlagsService,
    private readonly releaseReadinessService: ReleaseReadinessService,
  ) {}

  @Get('community-reports')
  @RequireAdminPermission(AdminPermission.MODERATE_COMMUNITY)
  listReports(@Query() query: ListReportsDto) {
    return this.adminService.listReports(query);
  }

  @Patch('community-reports/:id')
  @RequireAdminPermission(AdminPermission.MODERATE_COMMUNITY)
  actionReport(@Param('id') id: string, @Body() dto: ActionReportDto) {
    return this.adminService.actionReport(id, dto);
  }

  @Get('eligibility-applications')
  @RequireAdminPermission(AdminPermission.REVIEW_ELIGIBILITY)
  listEligibilityApplications(@Query() query: ListEligibilityDto) {
    return this.adminService.listEligibilityApplications(query);
  }

  @Patch('eligibility-applications/:userId')
  @RequireAdminPermission(AdminPermission.REVIEW_ELIGIBILITY)
  decideEligibility(@Param('userId') userId: string, @Body() dto: DecideEligibilityDto) {
    return this.adminService.decideEligibility(userId, dto);
  }

  @Get('support-tickets')
  @RequireAdminPermission(AdminPermission.MANAGE_SUPPORT)
  listTickets(@Query() query: ListTicketsDto) {
    return this.adminService.listTickets(query);
  }

  @Get('support-tickets/:id')
  @RequireAdminPermission(AdminPermission.MANAGE_SUPPORT)
  getTicket(@Param('id') id: string) {
    return this.adminService.getTicket(id);
  }

  @Patch('support-tickets/:id/reply')
  @RequireAdminPermission(AdminPermission.MANAGE_SUPPORT)
  replyToTicket(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: AdminReplyTicketDto,
  ) {
    return this.adminService.replyToTicket(user.id, id, dto);
  }

  @Get('promoted-campaigns')
  @RequireAdminPermission(AdminPermission.REVIEW_PROMOTIONS)
  listCampaigns(@Query() query: ListCampaignsDto) {
    return this.adminService.listCampaigns(query);
  }

  @Patch('promoted-campaigns/:id')
  @RequireAdminPermission(AdminPermission.REVIEW_PROMOTIONS)
  decideCampaign(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: DecideCampaignDto,
  ) {
    return this.adminService.decideCampaign(user.id, id, dto);
  }

  // --- Admin RBAC (Build Session 9 Part 19) -------------------------------

  // No @RequireAdminPermission tag — any ADMIN can read its own grants,
  // same "floor is plain ADMIN" default every other untagged route has.
  @Get('me/permissions')
  getMyPermissions(@CurrentUser() user: AuthenticatedUser) {
    return this.adminService.getMyPermissions(user.id);
  }

  @Get('admins')
  @RequireAdminPermission(AdminPermission.MANAGE_ADMINS)
  listAdmins() {
    return this.adminService.listAdmins();
  }

  @Post('admins/:userId/permissions')
  @RequireAdminPermission(AdminPermission.MANAGE_ADMINS)
  grantPermission(
    @CurrentUser() user: AuthenticatedUser,
    @Param('userId') userId: string,
    @Body() dto: GrantAdminPermissionDto,
  ) {
    return this.adminService.grantPermission(user.id, userId, dto);
  }

  @Delete('admins/:userId/permissions/:permission')
  @RequireAdminPermission(AdminPermission.MANAGE_ADMINS)
  revokePermission(
    @CurrentUser() user: AuthenticatedUser,
    @Param('userId') userId: string,
    @Param('permission', new ParseEnumPipe(AdminPermission)) permission: AdminPermission,
  ) {
    return this.adminService.revokePermission(user.id, userId, permission);
  }

  // --- Feature Flags (Build Session 12 Part 15-17) -----------------------

  @Get('feature-flags')
  @RequireAdminPermission(AdminPermission.MANAGE_PLATFORM)
  listFeatureFlags() {
    return this.featureFlagsService.listAll();
  }

  @Post('feature-flags/:key')
  @RequireAdminPermission(AdminPermission.MANAGE_PLATFORM)
  upsertFeatureFlag(@Param('key') key: string, @Body() dto: UpsertFeatureFlagDto) {
    return this.featureFlagsService.upsert(key, dto);
  }

  @Delete('feature-flags/:key')
  @RequireAdminPermission(AdminPermission.MANAGE_PLATFORM)
  deleteFeatureFlag(@Param('key') key: string) {
    return this.featureFlagsService.delete(key);
  }

  // --- Release Readiness (Build Session 12 Part 15-17) --------------------

  @Get('release-readiness')
  @RequireAdminPermission(AdminPermission.MANAGE_PLATFORM)
  releaseReadiness() {
    return this.releaseReadinessService.check();
  }
}
