import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import {
  AdminPermission,
  CommunityReportStatus,
  CommunityReportTargetType,
  PromotedCampaignStatus,
  SupportTicketStatus,
  UserRole,
} from '@prisma/client';
import { AuditService } from '../../common/audit/audit.service';
import { paginationArgs, paginationMeta } from '../../common/pagination/pagination-query.dto';
import { PrismaService } from '../../prisma/prisma.service';
import { ActionReportDto } from './dto/action-report.dto';
import { DecideCampaignDto } from './dto/decide-campaign.dto';
import { DecideEligibilityDto } from './dto/decide-eligibility.dto';
import { GrantAdminPermissionDto } from './dto/grant-admin-permission.dto';
import { ListCampaignsDto } from './dto/list-campaigns.dto';
import { ListEligibilityDto } from './dto/list-eligibility.dto';
import { ListReportsDto } from './dto/list-reports.dto';
import { ListTicketsDto } from './dto/list-tickets.dto';
import { AdminReplyTicketDto } from './dto/reply-ticket.dto';

/**
 * Administration foundation — moderation queue for Community reports
 * (see CommunityReport's own doc comment: "only an admin workflow
 * (Part 10) moves it to REVIEWED/ACTIONED"), the affordability-program
 * review queue (Part 7), and the support-ticket staff queue. Gated by
 * `AdminPermissionGuard`, not a capability check — being an admin isn't
 * a Premium/Free distinction. As of Build Session 9 Part 19, each
 * surface additionally requires its own `AdminPermission` grant (see
 * AdminPermissionGuard's doc comment) — this service's own
 * grant/revoke methods are what an existing MANAGE_ADMINS holder uses
 * to manage that.
 */
@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AuditService,
  ) {}

  // --- Community moderation --------------------------------------------

  async listReports(query: ListReportsDto) {
    const where = { status: query.status };
    const [reports, total] = await Promise.all([
      this.prisma.communityReport.findMany({
        where,
        orderBy: { createdAt: 'asc' },
        ...paginationArgs(query),
      }),
      this.prisma.communityReport.count({ where }),
    ]);
    return { data: reports, meta: paginationMeta(query, total) };
  }

  async actionReport(id: string, dto: ActionReportDto) {
    if (dto.status === CommunityReportStatus.OPEN) {
      throw new BadRequestException('A report cannot be actioned back to OPEN.');
    }
    const report = await this.prisma.communityReport.findUnique({ where: { id } });
    if (!report) throw new NotFoundException('Report not found.');

    const shouldRemoveContent =
      dto.status === CommunityReportStatus.ACTIONED && dto.removeContent === true;
    const shouldRemovePost =
      shouldRemoveContent && report.targetType === CommunityReportTargetType.POST;
    const shouldRemoveMedia =
      shouldRemoveContent && report.targetType === CommunityReportTargetType.MEDIA_ASSET;

    const [updated] = await this.prisma.$transaction([
      this.prisma.communityReport.update({ where: { id }, data: { status: dto.status } }),
      ...(shouldRemovePost
        ? [
            this.prisma.communityPost.update({
              where: { id: report.targetId },
              data: { moderationStatus: 'REMOVED' },
            }),
          ]
        : []),
      ...(shouldRemoveMedia
        ? [
            this.prisma.mediaAsset.update({
              where: { id: report.targetId },
              data: { moderationState: 'REMOVED' },
            }),
            this.prisma.mediaModerationResult.create({
              data: {
                mediaAssetId: report.targetId,
                status: 'REMOVED',
                reasonCode: 'ADMIN_REPORT_ACTIONED',
              },
            }),
          ]
        : []),
    ]);
    return updated;
  }

  // --- Affordability eligibility review --------------------------------

  async listEligibilityApplications(query: ListEligibilityDto) {
    const where = { status: query.status };
    const [applications, total] = await Promise.all([
      this.prisma.affordabilityEligibility.findMany({
        where,
        orderBy: { submittedAt: 'asc' },
        ...paginationArgs(query),
      }),
      this.prisma.affordabilityEligibility.count({ where }),
    ]);
    return { data: applications, meta: paginationMeta(query, total) };
  }

  async decideEligibility(userId: string, dto: DecideEligibilityDto) {
    if (dto.status === 'PENDING') {
      throw new BadRequestException('A decision must be APPROVED or REJECTED.');
    }
    const existing = await this.prisma.affordabilityEligibility.findUnique({ where: { userId } });
    if (!existing) throw new NotFoundException('No eligibility application for this user.');

    return this.prisma.affordabilityEligibility.update({
      where: { userId },
      data: { status: dto.status, reviewedAt: new Date() },
    });
  }

  // --- Support ticket queue ---------------------------------------------

  async listTickets(query: ListTicketsDto) {
    const where = { status: query.status };
    const [tickets, total] = await Promise.all([
      this.prisma.supportTicket.findMany({
        where,
        orderBy: { createdAt: 'asc' },
        ...paginationArgs(query),
      }),
      this.prisma.supportTicket.count({ where }),
    ]);
    return { data: tickets, meta: paginationMeta(query, total) };
  }

  async getTicket(id: string) {
    const ticket = await this.prisma.supportTicket.findUnique({ where: { id } });
    if (!ticket) throw new NotFoundException('Support ticket not found.');
    const replies = await this.prisma.supportTicketReply.findMany({
      where: { ticketId: id },
      orderBy: { createdAt: 'asc' },
    });
    return { ...ticket, replies };
  }

  async replyToTicket(adminUserId: string, id: string, dto: AdminReplyTicketDto) {
    const ticket = await this.prisma.supportTicket.findUnique({ where: { id } });
    if (!ticket) throw new NotFoundException('Support ticket not found.');

    const [reply] = await this.prisma.$transaction([
      this.prisma.supportTicketReply.create({
        data: { ticketId: id, authorId: adminUserId, isStaff: true, body: dto.body },
      }),
      this.prisma.supportTicket.update({
        where: { id },
        data: {
          status: dto.status ?? ticket.status,
          resolvedAt: dto.status === SupportTicketStatus.RESOLVED ? new Date() : ticket.resolvedAt,
        },
      }),
    ]);
    return reply;
  }

  // --- Ascend Promote review ----------------------------------------

  async listCampaigns(query: ListCampaignsDto) {
    const where = { status: query.status };
    const [campaigns, total] = await Promise.all([
      this.prisma.promotedCampaign.findMany({
        where,
        orderBy: { createdAt: 'asc' },
        ...paginationArgs(query),
      }),
      this.prisma.promotedCampaign.count({ where }),
    ]);
    return { data: campaigns, meta: paginationMeta(query, total) };
  }

  async decideCampaign(adminUserId: string, id: string, dto: DecideCampaignDto) {
    if (
      dto.status !== PromotedCampaignStatus.ACTIVE &&
      dto.status !== PromotedCampaignStatus.REJECTED
    ) {
      throw new BadRequestException('A decision must be ACTIVE or REJECTED.');
    }
    const campaign = await this.prisma.promotedCampaign.findUnique({ where: { id } });
    if (!campaign) throw new NotFoundException('Campaign not found.');
    if (campaign.status !== PromotedCampaignStatus.PENDING_REVIEW) {
      throw new BadRequestException('Only a PENDING_REVIEW campaign can be reviewed.');
    }

    return this.prisma.promotedCampaign.update({
      where: { id },
      data: { status: dto.status, reviewedAt: new Date(), reviewedBy: adminUserId },
    });
  }

  // --- Admin RBAC (Build Session 9 Part 19) ------------------------------

  async listAdmins() {
    const admins = await this.prisma.user.findMany({
      where: { role: UserRole.ADMIN },
      orderBy: { createdAt: 'asc' },
      select: {
        id: true,
        email: true,
        adminPermissionGrants: { select: { permission: true } },
      },
    });
    return admins.map((admin) => ({
      id: admin.id,
      email: admin.email,
      permissions: admin.adminPermissionGrants.map((grant) => grant.permission),
    }));
  }

  async grantPermission(
    grantedByUserId: string,
    targetUserId: string,
    dto: GrantAdminPermissionDto,
  ) {
    const target = await this.prisma.user.findUnique({ where: { id: targetUserId } });
    if (!target) throw new NotFoundException('User not found.');
    if (target.role !== UserRole.ADMIN) {
      throw new BadRequestException('Only an ADMIN-role account can hold an admin permission.');
    }

    await this.prisma.adminPermissionGrant.upsert({
      where: { userId_permission: { userId: targetUserId, permission: dto.permission } },
      update: {},
      create: { userId: targetUserId, permission: dto.permission },
    });
    await this.auditService.record({
      userId: grantedByUserId,
      action: 'admin_permission.granted',
      entityType: 'User',
      entityId: targetUserId,
      metadata: { permission: dto.permission },
    });

    return this.getMyPermissions(targetUserId);
  }

  async revokePermission(
    revokedByUserId: string,
    targetUserId: string,
    permission: AdminPermission,
  ) {
    await this.prisma.adminPermissionGrant.deleteMany({
      where: { userId: targetUserId, permission },
    });
    await this.auditService.record({
      userId: revokedByUserId,
      action: 'admin_permission.revoked',
      entityType: 'User',
      entityId: targetUserId,
      metadata: { permission },
    });

    return this.getMyPermissions(targetUserId);
  }

  /**
   * The caller's own permission grants — used both as the grant/revoke
   * return value and by `GET /admin/me/permissions`, which any ADMIN
   * can call (no specific permission tag) so the admin web app can
   * render only the nav items/actions that account actually has.
   */
  async getMyPermissions(userId: string) {
    const grants = await this.prisma.adminPermissionGrant.findMany({
      where: { userId },
      select: { permission: true },
    });
    return { userId, permissions: grants.map((grant) => grant.permission) };
  }
}
