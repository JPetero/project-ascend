import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { CommunityReportTargetType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CommunityService } from './community.service';

function post(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'post-1',
    authorId: 'author-1',
    ...overrides,
  };
}

function comment(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'comment-1',
    postId: 'post-1',
    authorId: 'commenter-1',
    ...overrides,
  };
}

describe('CommunityService', () => {
  let service: CommunityService;
  let prisma: {
    communityProfile: { upsert: jest.Mock; findUnique: jest.Mock; findMany: jest.Mock };
    communityPost: { findUnique: jest.Mock; delete: jest.Mock };
    communityComment: { findUnique: jest.Mock; delete: jest.Mock };
    communityFollow: { upsert: jest.Mock; deleteMany: jest.Mock; findUnique: jest.Mock };
    communityBlock: { upsert: jest.Mock; findFirst: jest.Mock };
    communityReport: { create: jest.Mock };
    $transaction: jest.Mock;
  };

  beforeEach(async () => {
    prisma = {
      communityProfile: { upsert: jest.fn(), findUnique: jest.fn(), findMany: jest.fn() },
      communityPost: { findUnique: jest.fn(), delete: jest.fn() },
      communityComment: { findUnique: jest.fn(), delete: jest.fn() },
      communityFollow: { upsert: jest.fn(), deleteMany: jest.fn(), findUnique: jest.fn() },
      communityBlock: { upsert: jest.fn(), findFirst: jest.fn() },
      communityReport: { create: jest.fn() },
      $transaction: jest.fn((ops: unknown[]) => Promise.resolve(ops)),
    };

    const moduleRef = await Test.createTestingModule({
      providers: [CommunityService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = moduleRef.get(CommunityService);
  });

  describe('follow', () => {
    it('rejects following yourself without touching the database', async () => {
      await expect(service.follow('user-1', 'user-1')).rejects.toBeInstanceOf(BadRequestException);
      expect(prisma.communityFollow.upsert).not.toHaveBeenCalled();
    });

    it('rejects following someone you have blocked, or who has blocked you', async () => {
      prisma.communityBlock.findFirst.mockResolvedValue({
        blockerId: 'user-1',
        blockedId: 'user-2',
      });

      await expect(service.follow('user-1', 'user-2')).rejects.toBeInstanceOf(NotFoundException);
      expect(prisma.communityFollow.upsert).not.toHaveBeenCalled();
    });

    it('upserts the follow row when nothing blocks it', async () => {
      prisma.communityBlock.findFirst.mockResolvedValue(null);

      await service.follow('user-1', 'user-2');

      expect(prisma.communityFollow.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { followerId_followingId: { followerId: 'user-1', followingId: 'user-2' } },
        }),
      );
    });
  });

  describe('block', () => {
    it('rejects blocking yourself', async () => {
      await expect(service.block('user-1', 'user-1')).rejects.toBeInstanceOf(BadRequestException);
      expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    it('also severs any existing follow relationship in both directions', async () => {
      await service.block('user-1', 'user-2');

      expect(prisma.$transaction).toHaveBeenCalledTimes(1);
      const ops = prisma.$transaction.mock.calls[0][0] as unknown[];
      expect(ops).toHaveLength(2);
      expect(prisma.communityBlock.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { blockerId_blockedId: { blockerId: 'user-1', blockedId: 'user-2' } },
        }),
      );
      expect(prisma.communityFollow.deleteMany).toHaveBeenCalledWith({
        where: {
          OR: [
            { followerId: 'user-1', followingId: 'user-2' },
            { followerId: 'user-2', followingId: 'user-1' },
          ],
        },
      });
    });
  });

  describe('deletePost', () => {
    it('rejects deleting a post that does not exist', async () => {
      prisma.communityPost.findUnique.mockResolvedValue(null);

      await expect(service.deletePost('user-1', 'missing')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('rejects deleting someone else’s post', async () => {
      prisma.communityPost.findUnique.mockResolvedValue(post({ authorId: 'someone-else' }));

      await expect(service.deletePost('user-1', 'post-1')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
      expect(prisma.communityPost.delete).not.toHaveBeenCalled();
    });

    it('deletes a post owned by the caller', async () => {
      prisma.communityPost.findUnique.mockResolvedValue(post({ authorId: 'user-1' }));

      await service.deletePost('user-1', 'post-1');

      expect(prisma.communityPost.delete).toHaveBeenCalledWith({ where: { id: 'post-1' } });
    });
  });

  describe('deleteComment', () => {
    it('rejects deleting a comment that does not exist', async () => {
      prisma.communityComment.findUnique.mockResolvedValue(null);

      await expect(service.deleteComment('user-1', 'missing')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('allows the comment author to delete their own comment', async () => {
      prisma.communityComment.findUnique.mockResolvedValue(comment({ authorId: 'user-1' }));
      prisma.communityPost.findUnique.mockResolvedValue(post({ authorId: 'someone-else' }));

      await service.deleteComment('user-1', 'comment-1');

      expect(prisma.communityComment.delete).toHaveBeenCalledWith({ where: { id: 'comment-1' } });
    });

    it('allows the post author to moderate a comment they did not write', async () => {
      prisma.communityComment.findUnique.mockResolvedValue(comment({ authorId: 'commenter-1' }));
      prisma.communityPost.findUnique.mockResolvedValue(post({ authorId: 'user-1' }));

      await service.deleteComment('user-1', 'comment-1');

      expect(prisma.communityComment.delete).toHaveBeenCalledWith({ where: { id: 'comment-1' } });
    });

    it('rejects a bystander who is neither the comment author nor the post author', async () => {
      prisma.communityComment.findUnique.mockResolvedValue(comment({ authorId: 'commenter-1' }));
      prisma.communityPost.findUnique.mockResolvedValue(post({ authorId: 'author-1' }));

      await expect(service.deleteComment('bystander', 'comment-1')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
      expect(prisma.communityComment.delete).not.toHaveBeenCalled();
    });
  });

  describe('report', () => {
    it('rejects reporting a post that does not exist', async () => {
      prisma.communityPost.findUnique.mockResolvedValue(null);

      await expect(
        service.report('user-1', {
          targetType: CommunityReportTargetType.POST,
          targetId: 'missing',
          reason: 'spam',
        }),
      ).rejects.toBeInstanceOf(NotFoundException);
      expect(prisma.communityReport.create).not.toHaveBeenCalled();
    });

    it('creates an OPEN report when the target exists', async () => {
      prisma.communityPost.findUnique.mockResolvedValue(post());
      prisma.communityReport.create.mockResolvedValue({
        id: 'report-1',
        status: 'OPEN',
        createdAt: new Date(),
      });

      const result = await service.report('user-1', {
        targetType: CommunityReportTargetType.POST,
        targetId: 'post-1',
        reason: 'spam',
      });

      expect(result.status).toBe('OPEN');
      expect(prisma.communityReport.create).toHaveBeenCalledWith({
        data: {
          reporterId: 'user-1',
          targetType: CommunityReportTargetType.POST,
          targetId: 'post-1',
          reason: 'spam',
        },
      });
    });
  });

  describe('upsertOwnProfile', () => {
    it('upserts keyed on the caller’s own userId', async () => {
      prisma.communityProfile.upsert.mockResolvedValue({
        userId: 'user-1',
        displayName: 'Ada',
        bio: null,
        avatarUrl: null,
        isTrainer: false,
      });

      await service.upsertOwnProfile('user-1', { displayName: 'Ada' });

      expect(prisma.communityProfile.upsert).toHaveBeenCalledWith(
        expect.objectContaining({ where: { userId: 'user-1' } }),
      );
    });
  });
});
