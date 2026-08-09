import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { CommunityReportTargetType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { FriendsService } from '../friends/friends.service';
import { MediaService } from '../media/media.service';
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
    communityPost: {
      findUnique: jest.Mock;
      delete: jest.Mock;
      create: jest.Mock;
      count: jest.Mock;
    };
    communityComment: { findUnique: jest.Mock; delete: jest.Mock };
    communityFollow: {
      upsert: jest.Mock;
      deleteMany: jest.Mock;
      findUnique: jest.Mock;
      count: jest.Mock;
    };
    communityBlock: { upsert: jest.Mock; findFirst: jest.Mock; findMany: jest.Mock };
    communityReport: { create: jest.Mock };
    $transaction: jest.Mock;
  };
  let mediaService: {
    getById: jest.Mock;
    setVisibility: jest.Mock;
    getObjectUrl: jest.Mock;
    attachUsage: jest.Mock;
  };
  let friendsService: { severTies: jest.Mock; areFriends: jest.Mock };

  beforeEach(async () => {
    prisma = {
      communityProfile: { upsert: jest.fn(), findUnique: jest.fn(), findMany: jest.fn() },
      communityPost: {
        findUnique: jest.fn(),
        delete: jest.fn(),
        create: jest.fn(),
        count: jest.fn(),
      },
      communityComment: { findUnique: jest.fn(), delete: jest.fn() },
      communityFollow: {
        upsert: jest.fn(),
        deleteMany: jest.fn(),
        findUnique: jest.fn(),
        count: jest.fn(),
      },
      communityBlock: { upsert: jest.fn(), findFirst: jest.fn(), findMany: jest.fn() },
      communityReport: { create: jest.fn() },
      $transaction: jest.fn((ops: unknown[]) => Promise.resolve(ops)),
    };
    prisma.communityPost.count.mockResolvedValue(0);
    prisma.communityFollow.count.mockResolvedValue(0);
    prisma.communityFollow.findUnique.mockResolvedValue(null);
    prisma.communityBlock.findFirst.mockResolvedValue(null);
    mediaService = {
      getById: jest.fn(),
      setVisibility: jest.fn(),
      getObjectUrl: jest.fn().mockReturnValue('/media/objects/key.jpg'),
      attachUsage: jest.fn(),
    };
    friendsService = { severTies: jest.fn(), areFriends: jest.fn() };

    const moduleRef = await Test.createTestingModule({
      providers: [
        CommunityService,
        { provide: PrismaService, useValue: prisma },
        { provide: MediaService, useValue: mediaService },
        { provide: FriendsService, useValue: friendsService },
      ],
    }).compile();

    service = moduleRef.get(CommunityService);
  });

  describe('createPost with a Media Platform asset', () => {
    it("404s a media asset the caller doesn't own", async () => {
      mediaService.getById.mockResolvedValue({
        ownerId: 'someone-else',
        storageKey: 'key.jpg',
        processingState: 'READY',
        moderationState: 'APPROVED',
      });

      await expect(
        service.createPost('author-1', {
          mediaType: 'IMAGE',
          mediaAssetId: 'asset-1',
        } as never),
      ).rejects.toBeInstanceOf(NotFoundException);
      expect(prisma.communityPost.create).not.toHaveBeenCalled();
    });

    it('rejects a media asset that has not finished processing', async () => {
      mediaService.getById.mockResolvedValue({
        ownerId: 'author-1',
        storageKey: 'key.jpg',
        processingState: 'PENDING',
        moderationState: 'PENDING',
      });

      await expect(
        service.createPost('author-1', {
          mediaType: 'IMAGE',
          mediaAssetId: 'asset-1',
        } as never),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects a removed media asset', async () => {
      mediaService.getById.mockResolvedValue({
        ownerId: 'author-1',
        storageKey: 'key.jpg',
        processingState: 'READY',
        moderationState: 'REMOVED',
      });

      await expect(
        service.createPost('author-1', {
          mediaType: 'IMAGE',
          mediaAssetId: 'asset-1',
        } as never),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });
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

  describe('listBlocked', () => {
    it('maps blocked rows to display-ready entries, most recent first', async () => {
      const blockedAt = new Date();
      prisma.communityBlock.findMany.mockResolvedValue([
        {
          blockedId: 'user-2',
          createdAt: blockedAt,
          blocked: { communityProfile: { displayName: 'Bea', avatarUrl: 'a.png' } },
        },
        {
          blockedId: 'user-3',
          createdAt: blockedAt,
          blocked: { communityProfile: null },
        },
      ]);

      const result = await service.listBlocked('user-1');

      expect(prisma.communityBlock.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { blockerId: 'user-1' } }),
      );
      expect(result).toEqual([
        { userId: 'user-2', displayName: 'Bea', avatarUrl: 'a.png', blockedAt },
        { userId: 'user-3', displayName: null, avatarUrl: null, blockedAt },
      ]);
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

  describe('getProfile visibility — Build Session 9 Part 2', () => {
    function profileWith(visibility: string) {
      return {
        userId: 'target-1',
        displayName: 'Target',
        bio: null,
        avatarUrl: null,
        isTrainer: false,
        visibility,
        avatarMediaAsset: null,
        coverMediaAsset: null,
      };
    }

    it('always lets the owner see their own profile regardless of visibility', async () => {
      prisma.communityProfile.findUnique.mockResolvedValue(profileWith('PRIVATE'));

      const result = await service.getProfile('target-1', 'target-1');

      expect(result.userId).toBe('target-1');
    });

    it('lets anyone see a PUBLIC profile', async () => {
      prisma.communityProfile.findUnique.mockResolvedValue(profileWith('PUBLIC'));

      const result = await service.getProfile('viewer-1', 'target-1');

      expect(result.userId).toBe('target-1');
    });

    it('404s a PRIVATE profile for anyone other than its owner', async () => {
      prisma.communityProfile.findUnique.mockResolvedValue(profileWith('PRIVATE'));

      await expect(service.getProfile('viewer-1', 'target-1')).rejects.toThrow(NotFoundException);
    });

    it('404s a FOLLOWERS profile for a non-follower', async () => {
      prisma.communityProfile.findUnique.mockResolvedValue(profileWith('FOLLOWERS'));
      prisma.communityFollow.findUnique.mockResolvedValue(null);

      await expect(service.getProfile('viewer-1', 'target-1')).rejects.toThrow(NotFoundException);
    });

    it('shows a FOLLOWERS profile to someone who follows the target', async () => {
      prisma.communityProfile.findUnique.mockResolvedValue(profileWith('FOLLOWERS'));
      prisma.communityFollow.findUnique.mockResolvedValue({
        followerId: 'viewer-1',
        followingId: 'target-1',
      });

      const result = await service.getProfile('viewer-1', 'target-1');

      expect(result.userId).toBe('target-1');
    });

    it('404s a FRIENDS profile for a non-friend even if they follow', async () => {
      prisma.communityProfile.findUnique.mockResolvedValue(profileWith('FRIENDS'));
      prisma.communityFollow.findUnique.mockResolvedValue({
        followerId: 'viewer-1',
        followingId: 'target-1',
      });
      friendsService.areFriends.mockResolvedValue(false);

      await expect(service.getProfile('viewer-1', 'target-1')).rejects.toThrow(NotFoundException);
    });

    it('shows a FRIENDS profile to an actual mutual friend', async () => {
      prisma.communityProfile.findUnique.mockResolvedValue(profileWith('FRIENDS'));
      prisma.communityFollow.findUnique.mockResolvedValue(null);
      friendsService.areFriends.mockResolvedValue(true);

      const result = await service.getProfile('viewer-1', 'target-1');

      expect(result.userId).toBe('target-1');
      expect(friendsService.areFriends).toHaveBeenCalledWith('viewer-1', 'target-1');
    });
  });
});
