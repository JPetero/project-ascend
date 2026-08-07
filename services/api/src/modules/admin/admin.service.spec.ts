import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminService } from './admin.service';

describe('AdminService', () => {
  let service: AdminService;
  let prisma: {
    communityReport: {
      findMany: jest.Mock;
      count: jest.Mock;
      findUnique: jest.Mock;
      update: jest.Mock;
    };
    communityPost: { update: jest.Mock };
    affordabilityEligibility: { findMany: jest.Mock; count: jest.Mock; findUnique: jest.Mock };
    supportTicket: { findMany: jest.Mock; count: jest.Mock; findUnique: jest.Mock };
    supportTicketReply: { findMany: jest.Mock };
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
      affordabilityEligibility: { findMany: jest.fn(), count: jest.fn(), findUnique: jest.fn() },
      supportTicket: { findMany: jest.fn(), count: jest.fn(), findUnique: jest.fn() },
      supportTicketReply: { findMany: jest.fn().mockResolvedValue([]) },
      $transaction: jest.fn((ops: unknown[]) => Promise.all(ops)),
    };

    const moduleRef = await Test.createTestingModule({
      providers: [AdminService, { provide: PrismaService, useValue: prisma }],
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
        targetType: 'POST',
        targetId: 'post-1',
        status: 'OPEN',
      });

      await service.actionReport('report-1', { status: 'REVIEWED' as never });

      expect(prisma.communityPost.update).not.toHaveBeenCalled();
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
  });

  describe('replyToTicket', () => {
    it('404s for a ticket that does not exist', async () => {
      prisma.supportTicket.findUnique.mockResolvedValue(null);

      await expect(
        service.replyToTicket('admin-1', 'ticket-1', { body: 'reply' }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });
});
