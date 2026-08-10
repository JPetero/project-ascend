import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import {
  AdminPermission,
  CommunityReportStatus,
  CommunityReportTargetType,
  NotificationType,
  PromotedCampaignStatus,
  SupportTicketCategory,
  SupportTicketStatus,
  TrainerVerificationStatus,
  UserRole,
} from '@prisma/client';
import { AuditService } from '../../common/audit/audit.service';
import { paginationArgs, paginationMeta } from '../../common/pagination/pagination-query.dto';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../../prisma/prisma.service';
import { ActionReportDto } from './dto/action-report.dto';
import { DecideCampaignDto } from './dto/decide-campaign.dto';
import { DecideEligibilityDto } from './dto/decide-eligibility.dto';
import { DecideTrainerVerificationDto } from './dto/decide-trainer-verification.dto';
import { GrantAdminPermissionDto } from './dto/grant-admin-permission.dto';
import { ListCampaignsDto } from './dto/list-campaigns.dto';
import { ListEligibilityDto } from './dto/list-eligibility.dto';
import { ListReportsDto } from './dto/list-reports.dto';
import { ListTicketsDto } from './dto/list-tickets.dto';
import { ListTrainerVerificationDto } from './dto/list-trainer-verification.dto';
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
    private readonly notifications: NotificationsService,
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

    // Build Session 12 Part 2 — notify the reporter their report has an
    // update, never the specifics of the decision (no target
    // type/content/removal outcome in the copy) so the notification/lock
    // screen never reveals moderation details.
    await this.notifications.notify(
      report.reporterId,
      NotificationType.MODERATION_DECISION,
      'Report update',
      "There's an update about one of your Ascend reports.",
      report.id,
    );

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

    const updated = await this.prisma.affordabilityEligibility.update({
      where: { userId },
      data: { status: dto.status, reviewedAt: new Date() },
    });

    await this.notifications.notify(
      userId,
      NotificationType.ELIGIBILITY_VERIFICATION_UPDATE,
      'Eligibility application update',
      'Your Ascend affordability program application has an update.',
    );

    return updated;
  }

  // --- Trainer verification review (Build Session 12 Part 25-26) --------

  async listTrainerVerificationApplications(query: ListTrainerVerificationDto) {
    const where = { status: query.status };
    const [applications, total] = await Promise.all([
      this.prisma.trainerVerificationApplication.findMany({
        where,
        orderBy: { submittedAt: 'asc' },
        ...paginationArgs(query),
      }),
      this.prisma.trainerVerificationApplication.count({ where }),
    ]);
    return { data: applications, meta: paginationMeta(query, total) };
  }

  async decideTrainerVerification(userId: string, dto: DecideTrainerVerificationDto) {
    if (dto.status === TrainerVerificationStatus.PENDING) {
      throw new BadRequestException('A decision must be APPROVED or REJECTED.');
    }
    const existing = await this.prisma.trainerVerificationApplication.findUnique({
      where: { userId },
    });
    if (!existing) {
      throw new NotFoundException('No trainer verification application for this user.');
    }

    const [updated] = await this.prisma.$transaction([
      this.prisma.trainerVerificationApplication.update({
        where: { userId },
        data: { status: dto.status, reviewedAt: new Date() },
      }),
      // A CommunityProfile might not exist yet (the user never set one
      // up) — updateMany is a safe no-op rather than a 404 in that edge
      // case; the application's own status is still recorded either way.
      this.prisma.communityProfile.updateMany({
        where: { userId },
        data: { verifiedTrainer: dto.status === TrainerVerificationStatus.APPROVED },
      }),
    ]);

    await this.notifications.notify(
      userId,
      NotificationType.TRAINER_VERIFICATION_UPDATE,
      'Trainer verification update',
      'Your Ascend trainer verification application has an update.',
    );

    return updated;
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

    // Build Session 12 Part 2 — a moderation appeal is filed as a Support
    // ticket (SupportTicketCategory.MODERATION_APPEAL), so it goes
    // through this same reply path; it gets its own notification
    // category so the user can tell an appeal update apart from an
    // ordinary support reply. A status change (e.g. resolved) is the
    // more significant event when both happen in the same admin action,
    // so it takes priority over the plain "you got a reply" copy. Never
    // put the reply body or ticket subject in the notification — no
    // ticket contents on the lock screen.
    const isAppeal = ticket.category === SupportTicketCategory.MODERATION_APPEAL;
    const statusChanged = dto.status !== undefined && dto.status !== ticket.status;
    if (isAppeal) {
      await this.notifications.notify(
        ticket.userId,
        NotificationType.MODERATION_APPEAL_UPDATE,
        'Appeal update',
        'Your Ascend moderation appeal has an update.',
        id,
      );
    } else if (statusChanged) {
      await this.notifications.notify(
        ticket.userId,
        NotificationType.SUPPORT_STATUS_CHANGED,
        'Support ticket update',
        'Your Ascend support ticket status changed.',
        id,
      );
    } else {
      await this.notifications.notify(
        ticket.userId,
        NotificationType.SUPPORT_REPLY,
        'Support ticket update',
        'Your Ascend support ticket has an update.',
        id,
      );
    }

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

    const updated = await this.prisma.promotedCampaign.update({
      where: { id },
      data: { status: dto.status, reviewedAt: new Date(), reviewedBy: adminUserId },
    });

    await this.notifications.notify(
      campaign.creatorId,
      NotificationType.PROMOTE_REVIEW,
      'Promote campaign reviewed',
      'One of your Ascend Promote campaigns has been reviewed.',
      id,
    );

    return updated;
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
