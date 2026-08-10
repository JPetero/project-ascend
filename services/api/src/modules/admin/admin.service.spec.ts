import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AuditService } from '../../common/audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminService } from './admin.service';

describe('AdminService', () => {
  let service: AdminService;
  let auditService: { record: jest.Mock };
  let notifications: { notify: jest.Mock };
  let prisma: {
    communityReport: {
      findMany: jest.Mock;
      count: jest.Mock;
      findUnique: jest.Mock;
      update: jest.Mock;
    };
    communityPost: { update: jest.Mock };
    affordabilityEligibility: {
      findMany: jest.Mock;
      count: jest.Mock;
      findUnique: jest.Mock;
      update: jest.Mock;
    };
    supportTicket: {
      findMany: jest.Mock;
      count: jest.Mock;
      findUnique: jest.Mock;
      update: jest.Mock;
    };
    supportTicketReply: { findMany: jest.Mock; create: jest.Mock };
    promotedCampaign: {
      findMany: jest.Mock;
      count: jest.Mock;
      findUnique: jest.Mock;
      update: jest.Mock;
    };
    user: { findMany: jest.Mock; findUnique: jest.Mock };
    adminPermissionGrant: {
      findMany: jest.Mock;
      upsert: jest.Mock;
      deleteMany: jest.Mock;
    };
    trainerVerificationApplication: {
      findMany: jest.Mock;
      count: jest.Mock;
      findUnique: jest.Mock;
      update: jest.Mock;
    };
    communityProfile: { updateMany: jest.Mock };
    $transaction: jest.Mock;
  };

  beforeEach(async () => {
    prisma = {
      communityReport: {
        findMany: jest.fn(),
        count: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      communityPost: { update: jest.fn() },
      affordabilityEligibility: {
        findMany: jest.fn(),
        count: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      supportTicket: {
        findMany: jest.fn(),
        count: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      supportTicketReply: { findMany: jest.fn().mockResolvedValue([]), create: jest.fn() },
      promotedCampaign: {
        findMany: jest.fn(),
        count: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      user: { findMany: jest.fn(), findUnique: jest.fn() },
      adminPermissionGrant: {
        findMany: jest.fn().mockResolvedValue([]),
        upsert: jest.fn(),
        deleteMany: jest.fn(),
      },
      trainerVerificationApplication: {
        findMany: jest.fn(),
        count: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      communityProfile: { updateMany: jest.fn() },
      $transaction: jest.fn((ops: unknown[]) => Promise.all(ops)),
    };
    auditService = { record: jest.fn() };
    notifications = { notify: jest.fn().mockResolvedValue(undefined) };

    const moduleRef = await Test.createTestingModule({
      providers: [
        AdminService,
        { provide: PrismaService, useValue: prisma },
        { provide: AuditService, useValue: auditService },
        { provide: NotificationsService, useValue: notifications },
      ],
    }).compile();

    service = moduleRef.get(AdminService);
  });

  describe('actionReport', () => {
    it('rejects actioning a report back to OPEN', async () => {
      await expect(
        service.actionReport('report-1', { status: 'OPEN' as never }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('404s for a report that does not exist', async () => {
      prisma.communityReport.findUnique.mockResolvedValue(null);

      await expect(
        service.actionReport('report-1', { status: 'REVIEWED' as never }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('marks a post REMOVED when actioned with removeContent on a POST target', async () => {
      prisma.communityReport.findUnique.mockResolvedValue({
        id: 'report-1',
        reporterId: 'reporter-1',
        targetType: 'POST',
        targetId: 'post-1',
        status: 'OPEN',
      });

      await service.actionReport('report-1', { status: 'ACTIONED' as never, removeContent: true });

      expect(prisma.communityPost.update).toHaveBeenCalledWith({
        where: { id: 'post-1' },
        data: { moderationStatus: 'REMOVED' },
      });
    });

    it('does not touch content when removeContent is not set', async () => {
      prisma.communityReport.findUnique.mockResolvedValue({
        id: 'report-1',
        reporterId: 'reporter-1',
        targetType: 'POST',
        targetId: 'post-1',
        status: 'OPEN',
      });

      await service.actionReport('report-1', { status: 'REVIEWED' as never });

      expect(prisma.communityPost.update).not.toHaveBeenCalled();
    });

    it('notifies the reporter of the decision, never the specifics', async () => {
      prisma.communityReport.findUnique.mockResolvedValue({
        id: 'report-1',
        reporterId: 'reporter-1',
        targetType: 'POST',
        targetId: 'post-1',
        status: 'OPEN',
      });

      await service.actionReport('report-1', { status: 'REVIEWED' as never });

      expect(notifications.notify).toHaveBeenCalledWith(
        'reporter-1',
        'MODERATION_DECISION',
        expect.any(String),
        expect.any(String),
        'report-1',
      );
      const [, , , body] = notifications.notify.mock.calls[0];
      expect(body).not.toMatch(/post|remove|target/i);
    });
  });

  describe('decideEligibility', () => {
    it('rejects a decision of PENDING', async () => {
      await expect(
        service.decideEligibility('user-1', { status: 'PENDING' as never }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('404s when the user never applied', async () => {
      prisma.affordabilityEligibility.findUnique.mockResolvedValue(null);

      await expect(
        service.decideEligibility('user-1', { status: 'APPROVED' as never }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('notifies the applicant of the decision', async () => {
      prisma.affordabilityEligibility.findUnique.mockResolvedValue({ userId: 'user-1' });
      prisma.affordabilityEligibility.update.mockResolvedValue({ userId: 'user-1' });

      await service.decideEligibility('user-1', { status: 'APPROVED' as never });

      expect(notifications.notify).toHaveBeenCalledWith(
        'user-1',
        'ELIGIBILITY_VERIFICATION_UPDATE',
        expect.any(String),
        expect.any(String),
      );
    });
  });

  describe('decideTrainerVerification', () => {
    it('rejects a decision of PENDING', async () => {
      await expect(
        service.decideTrainerVerification('user-1', { status: 'PENDING' as never }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('404s when the user never applied', async () => {
      prisma.trainerVerificationApplication.findUnique.mockResolvedValue(null);

      await expect(
        service.decideTrainerVerification('user-1', { status: 'APPROVED' as never }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('sets CommunityProfile.verifiedTrainer true on APPROVED', async () => {
      prisma.trainerVerificationApplication.findUnique.mockResolvedValue({ userId: 'user-1' });
      prisma.trainerVerificationApplication.update.mockResolvedValue({ userId: 'user-1' });
      prisma.communityProfile.updateMany.mockResolvedValue({ count: 1 });

      await service.decideTrainerVerification('user-1', { status: 'APPROVED' as never });

      expect(prisma.communityProfile.updateMany).toHaveBeenCalledWith({
        where: { userId: 'user-1' },
        data: { verifiedTrainer: true },
      });
    });

    it('sets CommunityProfile.verifiedTrainer false on REJECTED', async () => {
      prisma.trainerVerificationApplication.findUnique.mockResolvedValue({ userId: 'user-1' });
      prisma.trainerVerificationApplication.update.mockResolvedValue({ userId: 'user-1' });
      prisma.communityProfile.updateMany.mockResolvedValue({ count: 1 });

      await service.decideTrainerVerification('user-1', { status: 'REJECTED' as never });

      expect(prisma.communityProfile.updateMany).toHaveBeenCalledWith({
        where: { userId: 'user-1' },
        data: { verifiedTrainer: false },
      });
    });

    it('notifies the applicant of the decision', async () => {
      prisma.trainerVerificationApplication.findUnique.mockResolvedValue({ userId: 'user-1' });
      prisma.trainerVerificationApplication.update.mockResolvedValue({ userId: 'user-1' });
      prisma.communityProfile.updateMany.mockResolvedValue({ count: 1 });

      await service.decideTrainerVerification('user-1', { status: 'APPROVED' as never });

      expect(notifications.notify).toHaveBeenCalledWith(
        'user-1',
        'TRAINER_VERIFICATION_UPDATE',
        expect.any(String),
        expect.any(String),
      );
    });
  });

  describe('listTrainerVerificationApplications', () => {
    it('filters by status and paginates', async () => {
      prisma.trainerVerificationApplication.findMany.mockResolvedValue([{ userId: 'user-1' }]);
      prisma.trainerVerificationApplication.count.mockResolvedValue(1);

      const result = await service.listTrainerVerificationApplications({
        status: 'PENDING' as never,
        page: 1,
        limit: 20,
      } as never);

      expect(prisma.trainerVerificationApplication.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { status: 'PENDING' } }),
      );
      expect(result.data).toEqual([{ userId: 'user-1' }]);
    });
  });

  describe('replyToTicket', () => {
    it('404s for a ticket that does not exist', async () => {
      prisma.supportTicket.findUnique.mockResolvedValue(null);

      await expect(
        service.replyToTicket('admin-1', 'ticket-1', { body: 'reply' }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('notifies a plain support reply when the status is unchanged', async () => {
      prisma.supportTicket.findUnique.mockResolvedValue({
        id: 'ticket-1',
        userId: 'user-1',
        category: 'GENERAL',
        status: 'OPEN',
      });

      await service.replyToTicket('admin-1', 'ticket-1', { body: 'Thanks for reaching out.' });

      expect(notifications.notify).toHaveBeenCalledWith(
        'user-1',
        'SUPPORT_REPLY',
        expect.any(String),
        expect.any(String),
        'ticket-1',
      );
    });

    it('notifies a status change instead of a plain reply when status actually changes', async () => {
      prisma.supportTicket.findUnique.mockResolvedValue({
        id: 'ticket-1',
        userId: 'user-1',
        category: 'GENERAL',
        status: 'OPEN',
      });

      await service.replyToTicket('admin-1', 'ticket-1', {
        body: 'Resolved.',
        status: 'RESOLVED' as never,
      });

      expect(notifications.notify).toHaveBeenCalledWith(
        'user-1',
        'SUPPORT_STATUS_CHANGED',
        expect.any(String),
        expect.any(String),
        'ticket-1',
      );
    });

    it('notifies a moderation appeal update, not a plain support reply, for an appeal ticket', async () => {
      prisma.supportTicket.findUnique.mockResolvedValue({
        id: 'ticket-1',
        userId: 'user-1',
        category: 'MODERATION_APPEAL',
        status: 'OPEN',
      });

      await service.replyToTicket('admin-1', 'ticket-1', { body: 'Reviewed your appeal.' });

      expect(notifications.notify).toHaveBeenCalledWith(
        'user-1',
        'MODERATION_APPEAL_UPDATE',
        expect.any(String),
        expect.any(String),
        'ticket-1',
      );
    });

    it('never puts the reply body or ticket subject in the notification copy', async () => {
      prisma.supportTicket.findUnique.mockResolvedValue({
        id: 'ticket-1',
        userId: 'user-1',
        category: 'GENERAL',
        subject: 'My billing issue',
        status: 'OPEN',
      });

      await service.replyToTicket('admin-1', 'ticket-1', {
        body: 'Here is a very specific private detail about your account.',
      });

      const [, , , body] = notifications.notify.mock.calls[0];
      expect(body).not.toContain('very specific private detail');
      expect(body).not.toContain('My billing issue');
    });
  });

  describe('decideCampaign', () => {
    it('rejects a decision that is not ACTIVE or REJECTED', async () => {
      await expect(
        service.decideCampaign('admin-1', 'campaign-1', { status: 'PENDING_REVIEW' as never }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('404s a campaign that does not exist', async () => {
      prisma.promotedCampaign.findUnique.mockResolvedValue(null);

      await expect(
        service.decideCampaign('admin-1', 'campaign-1', { status: 'ACTIVE' as never }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('rejects reviewing a campaign that already left PENDING_REVIEW', async () => {
      prisma.promotedCampaign.findUnique.mockResolvedValue({
        id: 'campaign-1',
        status: 'ACTIVE',
      });

      await expect(
        service.decideCampaign('admin-1', 'campaign-1', { status: 'REJECTED' as never }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('activates a PENDING_REVIEW campaign and records the reviewer', async () => {
      prisma.promotedCampaign.findUnique.mockResolvedValue({
        id: 'campaign-1',
        creatorId: 'creator-1',
        status: 'PENDING_REVIEW',
      });

      await service.decideCampaign('admin-1', 'campaign-1', { status: 'ACTIVE' as never });

      expect(prisma.promotedCampaign.update).toHaveBeenCalledWith({
        where: { id: 'campaign-1' },
        data: expect.objectContaining({ status: 'ACTIVE', reviewedBy: 'admin-1' }),
      });
      expect(notifications.notify).toHaveBeenCalledWith(
        'creator-1',
        'PROMOTE_REVIEW',
        expect.any(String),
        expect.any(String),
        'campaign-1',
      );
    });
  });

  describe('listAdmins', () => {
    it('flattens each admin user with its granted permissions', async () => {
      prisma.user.findMany.mockResolvedValue([
        {
          id: 'admin-1',
          email: 'a@example.com',
          adminPermissionGrants: [{ permission: 'MODERATE_COMMUNITY' }],
        },
      ]);

      const admins = await service.listAdmins();

      expect(admins).toEqual([
        { id: 'admin-1', email: 'a@example.com', permissions: ['MODERATE_COMMUNITY'] },
      ]);
      expect(prisma.user.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { role: 'ADMIN' } }),
      );
    });
  });

  describe('grantPermission', () => {
    it('404s a user that does not exist', async () => {
      prisma.user.findUnique.mockResolvedValue(null);

      await expect(
        service.grantPermission('granter-1', 'user-1', {
          permission: 'MODERATE_COMMUNITY' as never,
        }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('refuses to grant an admin permission to a non-ADMIN account', async () => {
      prisma.user.findUnique.mockResolvedValue({ id: 'user-1', role: 'MEMBER' });

      await expect(
        service.grantPermission('granter-1', 'user-1', {
          permission: 'MODERATE_COMMUNITY' as never,
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(prisma.adminPermissionGrant.upsert).not.toHaveBeenCalled();
    });

    it('upserts the grant and records an audit event', async () => {
      prisma.user.findUnique.mockResolvedValue({ id: 'user-1', role: 'ADMIN' });

      await service.grantPermission('granter-1', 'user-1', {
        permission: 'MODERATE_COMMUNITY' as never,
      });

      expect(prisma.adminPermissionGrant.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { userId_permission: { userId: 'user-1', permission: 'MODERATE_COMMUNITY' } },
        }),
      );
      expect(auditService.record).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'granter-1',
          action: 'admin_permission.granted',
          entityId: 'user-1',
          metadata: { permission: 'MODERATE_COMMUNITY' },
        }),
      );
    });
  });

  describe('revokePermission', () => {
    it('deletes the grant and records an audit event', async () => {
      await service.revokePermission('revoker-1', 'user-1', 'MODERATE_COMMUNITY' as never);

      expect(prisma.adminPermissionGrant.deleteMany).toHaveBeenCalledWith({
        where: { userId: 'user-1', permission: 'MODERATE_COMMUNITY' },
      });
      expect(auditService.record).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'revoker-1',
          action: 'admin_permission.revoked',
          entityId: 'user-1',
          metadata: { permission: 'MODERATE_COMMUNITY' },
        }),
      );
    });
  });

  describe('getMyPermissions', () => {
    it('returns the flat permission list for a given user', async () => {
      prisma.adminPermissionGrant.findMany.mockResolvedValue([
        { permission: 'MODERATE_COMMUNITY' },
        { permission: 'MANAGE_SUPPORT' },
      ]);

      const result = await service.getMyPermissions('user-1');

      expect(result).toEqual({
        userId: 'user-1',
        permissions: ['MODERATE_COMMUNITY', 'MANAGE_SUPPORT'],
      });
    });
  });
});
