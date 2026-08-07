import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PromotedCampaignStatus } from '@prisma/client';
import { PROMOTE_MAX_IMPRESSIONS_PER_VIEWER_PER_DAY } from '../../common/policy/promote-policy';
import { CapabilityService } from '../../common/entitlements/capability.service';
import { AppCapability } from '../../common/entitlements/capability.util';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateCampaignDto } from './dto/create-campaign.dto';

/**
 * Ascend Promote — Founder Scenario 23's transparent-promotion
 * architecture. Every campaign starts PENDING_REVIEW and can never
 * serve an impression or click until an admin moves it to ACTIVE (see
 * AdminService.decideCampaign in the admin module). No live billing —
 * see build-session-7.md Part 11.
 */
@Injectable()
export class PromoteService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly capabilityService: CapabilityService,
  ) {}

  async createCampaign(creatorId: string, dto: CreateCampaignDto) {
    const hasAccess = await this.capabilityService.hasCapabilityForUser(
      creatorId,
      AppCapability.ASCEND_PROMOTE,
    );
    if (!hasAccess) {
      throw new ForbiddenException('Ascend Promote requires Premium.');
    }

    const post = await this.prisma.communityPost.findUnique({ where: { id: dto.postId } });
    if (!post) throw new NotFoundException('Post not found.');
    if (post.authorId !== creatorId) {
      throw new ForbiddenException('Only the post author can promote it.');
    }

    const campaign = await this.prisma.promotedCampaign.create({
      data: {
        creatorId,
        postId: dto.postId,
        budgetAmount: dto.budgetAmount,
        budgetCurrency: dto.budgetCurrency.toUpperCase(),
      },
    });
    return campaign;
  }

  async listMine(creatorId: string) {
    return this.prisma.promotedCampaign.findMany({
      where: { creatorId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async endCampaign(creatorId: string, id: string) {
    const campaign = await this.prisma.promotedCampaign.findUnique({ where: { id } });
    if (!campaign || campaign.creatorId !== creatorId) {
      throw new NotFoundException('Campaign not found.');
    }
    return this.prisma.promotedCampaign.update({
      where: { id },
      data: { status: PromotedCampaignStatus.ENDED, endedAt: new Date() },
    });
  }

  /**
   * Paid and organic metrics are read from entirely separate tables
   * and returned as two distinct objects — never summed into one
   * blended number. See this module's Prisma schema comment.
   */
  async getMetrics(creatorId: string, id: string) {
    const campaign = await this.prisma.promotedCampaign.findUnique({ where: { id } });
    if (!campaign || campaign.creatorId !== creatorId) {
      throw new NotFoundException('Campaign not found.');
    }

    const [organicLikes, organicComments, paidImpressions, paidClicks] = await Promise.all([
      this.prisma.communityLike.count({ where: { postId: campaign.postId } }),
      this.prisma.communityComment.count({ where: { postId: campaign.postId } }),
      this.prisma.promotedImpression.count({ where: { campaignId: id } }),
      this.prisma.promotedClick.count({ where: { campaignId: id } }),
    ]);

    return {
      campaignId: id,
      status: campaign.status,
      organic: { likes: organicLikes, comments: organicComments },
      promoted: { impressions: paidImpressions, clicks: paidClicks },
    };
  }

  /**
   * Never serves an impression for a campaign that isn't ACTIVE (a
   * PENDING_REVIEW campaign must never reach a viewer — Scenario 23's
   * explicit test requirement), and caps how many promoted impressions
   * the same viewer sees per day across every campaign, per
   * `PROMOTE_MAX_IMPRESSIONS_PER_VIEWER_PER_DAY`. Returns whether the
   * impression was actually recorded.
   */
  async recordImpression(viewerId: string, campaignId: string): Promise<{ recorded: boolean }> {
    const campaign = await this.prisma.promotedCampaign.findUnique({
      where: { id: campaignId },
    });
    if (!campaign || campaign.status !== PromotedCampaignStatus.ACTIVE) {
      return { recorded: false };
    }

    const startOfDay = new Date();
    startOfDay.setUTCHours(0, 0, 0, 0);
    const todaysImpressions = await this.prisma.promotedImpression.count({
      where: { viewerId, createdAt: { gte: startOfDay } },
    });
    if (todaysImpressions >= PROMOTE_MAX_IMPRESSIONS_PER_VIEWER_PER_DAY) {
      return { recorded: false };
    }

    await this.prisma.promotedImpression.create({ data: { campaignId, viewerId } });
    return { recorded: true };
  }

  async recordClick(viewerId: string, campaignId: string): Promise<{ recorded: boolean }> {
    const campaign = await this.prisma.promotedCampaign.findUnique({
      where: { id: campaignId },
    });
    if (!campaign || campaign.status !== PromotedCampaignStatus.ACTIVE) {
      return { recorded: false };
    }
    await this.prisma.promotedClick.create({ data: { campaignId, viewerId } });
    return { recorded: true };
  }
}
