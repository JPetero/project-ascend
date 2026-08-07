import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { CapabilityService } from '../../common/entitlements/capability.service';
import { PrismaService } from '../../prisma/prisma.service';
import { PromoteService } from './promote.service';

function campaign(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'campaign-1',
    creatorId: 'creator-1',
    postId: 'post-1',
    status: 'PENDING_REVIEW',
    budgetAmount: 50,
    budgetCurrency: 'USD',
    ...overrides,
  };
}

describe('PromoteService', () => {
  let service: PromoteService;
  let prisma: {
    communityPost: { findUnique: jest.Mock };
    communityLike: { count: jest.Mock };
    communityComment: { count: jest.Mock };
    promotedCampaign: {
      create: jest.Mock;
      findMany: jest.Mock;
      findUnique: jest.Mock;
      update: jest.Mock;
    };
    promotedImpression: { count: jest.Mock; create: jest.Mock };
    promotedClick: { count: jest.Mock; create: jest.Mock };
  };
  let capabilityService: { hasCapabilityForUser: jest.Mock };

  beforeEach(async () => {
    prisma = {
      communityPost: { findUnique: jest.fn() },
      communityLike: { count: jest.fn().mockResolvedValue(0) },
      communityComment: { count: jest.fn().mockResolvedValue(0) },
      promotedCampaign: {
        create: jest.fn(),
        findMany: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      promotedImpression: { count: jest.fn().mockResolvedValue(0), create: jest.fn() },
      promotedClick: { count: jest.fn().mockResolvedValue(0), create: jest.fn() },
    };
    capabilityService = { hasCapabilityForUser: jest.fn().mockResolvedValue(true) };

    const moduleRef = await Test.createTestingModule({
      providers: [
        PromoteService,
        { provide: PrismaService, useValue: prisma },
        { provide: CapabilityService, useValue: capabilityService },
      ],
    }).compile();

    service = moduleRef.get(PromoteService);
  });

  describe('createCampaign', () => {
    it('rejects a creator without Ascend Promote entitlement', async () => {
      capabilityService.hasCapabilityForUser.mockResolvedValue(false);

      await expect(
        service.createCampaign('creator-1', {
          postId: 'post-1',
          budgetAmount: 50,
          budgetCurrency: 'usd',
        }),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.promotedCampaign.create).not.toHaveBeenCalled();
    });

    it('rejects promoting a post the caller does not own', async () => {
      prisma.communityPost.findUnique.mockResolvedValue({ id: 'post-1', authorId: 'someone-else' });

      await expect(
        service.createCampaign('creator-1', {
          postId: 'post-1',
          budgetAmount: 50,
          budgetCurrency: 'usd',
        }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('404s a post that does not exist', async () => {
      prisma.communityPost.findUnique.mockResolvedValue(null);

      await expect(
        service.createCampaign('creator-1', {
          postId: 'post-1',
          budgetAmount: 50,
          budgetCurrency: 'usd',
        }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('creates a PENDING_REVIEW campaign for the post owner', async () => {
      prisma.communityPost.findUnique.mockResolvedValue({ id: 'post-1', authorId: 'creator-1' });
      prisma.promotedCampaign.create.mockResolvedValue(campaign());

      await service.createCampaign('creator-1', {
        postId: 'post-1',
        budgetAmount: 50,
        budgetCurrency: 'usd',
      });

      expect(prisma.promotedCampaign.create).toHaveBeenCalledWith({
        data: { creatorId: 'creator-1', postId: 'post-1', budgetAmount: 50, budgetCurrency: 'USD' },
      });
    });
  });

  describe('recordImpression', () => {
    it('never serves an impression for a PENDING_REVIEW campaign', async () => {
      prisma.promotedCampaign.findUnique.mockResolvedValue(campaign({ status: 'PENDING_REVIEW' }));

      const result = await service.recordImpression('viewer-1', 'campaign-1');

      expect(result).toEqual({ recorded: false });
      expect(prisma.promotedImpression.create).not.toHaveBeenCalled();
    });

    it('records an impression for an ACTIVE campaign under the daily cap', async () => {
      prisma.promotedCampaign.findUnique.mockResolvedValue(campaign({ status: 'ACTIVE' }));
      prisma.promotedImpression.count.mockResolvedValue(0);

      const result = await service.recordImpression('viewer-1', 'campaign-1');

      expect(result).toEqual({ recorded: true });
      expect(prisma.promotedImpression.create).toHaveBeenCalledWith({
        data: { campaignId: 'campaign-1', viewerId: 'viewer-1' },
      });
    });

    it('suppresses an impression once the viewer hits the daily frequency cap', async () => {
      prisma.promotedCampaign.findUnique.mockResolvedValue(campaign({ status: 'ACTIVE' }));
      prisma.promotedImpression.count.mockResolvedValue(3);

      const result = await service.recordImpression('viewer-1', 'campaign-1');

      expect(result).toEqual({ recorded: false });
      expect(prisma.promotedImpression.create).not.toHaveBeenCalled();
    });
  });

  describe('recordClick', () => {
    it('never records a click for a non-ACTIVE campaign', async () => {
      prisma.promotedCampaign.findUnique.mockResolvedValue(campaign({ status: 'REJECTED' }));

      const result = await service.recordClick('viewer-1', 'campaign-1');

      expect(result).toEqual({ recorded: false });
      expect(prisma.promotedClick.create).not.toHaveBeenCalled();
    });
  });

  describe('getMetrics', () => {
    it('returns organic and promoted metrics as two separate objects, never blended', async () => {
      prisma.promotedCampaign.findUnique.mockResolvedValue(campaign());
      prisma.communityLike.count.mockResolvedValue(10);
      prisma.communityComment.count.mockResolvedValue(4);
      prisma.promotedImpression.count.mockResolvedValue(200);
      prisma.promotedClick.count.mockResolvedValue(15);

      const metrics = await service.getMetrics('creator-1', 'campaign-1');

      expect(metrics.organic).toEqual({ likes: 10, comments: 4 });
      expect(metrics.promoted).toEqual({ impressions: 200, clicks: 15 });
    });

    it('404s a campaign owned by someone else', async () => {
      prisma.promotedCampaign.findUnique.mockResolvedValue(campaign({ creatorId: 'someone-else' }));

      await expect(service.getMetrics('creator-1', 'campaign-1')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });
});
