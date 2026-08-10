import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  CommunityComment,
  CommunityModerationStatus,
  CommunityPost,
  CommunityProfileVisibility,
  CommunityVisibility,
  Prisma,
} from '@prisma/client';
import { paginationArgs, paginationMeta } from '../../common/pagination/pagination-query.dto';
import { PrismaService } from '../../prisma/prisma.service';
import { FriendsService } from '../friends/friends.service';
import { MediaService } from '../media/media.service';
import { CreateCommunityCommentDto } from './dto/create-community-comment.dto';
import { CreateCommunityPostDto } from './dto/create-community-post.dto';
import { CreateCommunityReportDto } from './dto/create-community-report.dto';
import { QueryCommunityPostsDto } from './dto/query-community-posts.dto';
import { UpsertCommunityProfileDto } from './dto/upsert-community-profile.dto';

const PROFILE_SELECT = {
  userId: true,
  displayName: true,
  bio: true,
  avatarUrl: true,
  isTrainer: true,
  verifiedTrainer: true,
  visibility: true,
  avatarMediaAsset: { select: { storageKey: true } },
  coverMediaAsset: { select: { storageKey: true } },
} as const;

type ProfileSummary = Prisma.CommunityProfileGetPayload<{ select: typeof PROFILE_SELECT }>;
type HydratedProfile = Omit<ProfileSummary, 'avatarMediaAsset' | 'coverMediaAsset'> & {
  coverUrl: string | null;
};

/**
 * Community profiles, posts (including Reels — a VIDEO post is just a
 * post, see CommunityPostMediaType), likes, comments, saves, follows,
 * blocks, and reports — Founder Scenario 21's MVP. See
 * packages/docs/build-session-7.md Part 4 and
 * packages/docs/product/user-scenario-bible.md for the full policy this
 * implements: no fake engagement, no automatic external-platform
 * publishing, moderation-before-promotion (Ascend Promote is a later
 * part; this module only carries the moderationStatus field it will
 * need), and blocking severs any existing follow in both directions.
 */
@Injectable()
export class CommunityService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly mediaService: MediaService,
    private readonly friendsService: FriendsService,
  ) {}

  // --- Profiles ---------------------------------------------------------

  async upsertOwnProfile(userId: string, dto: UpsertCommunityProfileDto) {
    const profile = await this.prisma.communityProfile.upsert({
      where: { userId },
      update: {
        displayName: dto.displayName,
        bio: dto.bio,
        avatarUrl: dto.avatarUrl,
        ...(dto.isTrainer !== undefined ? { isTrainer: dto.isTrainer } : {}),
        ...(dto.visibility !== undefined ? { visibility: dto.visibility } : {}),
      },
      create: {
        userId,
        displayName: dto.displayName,
        bio: dto.bio,
        avatarUrl: dto.avatarUrl,
        isTrainer: dto.isTrainer ?? false,
        visibility: dto.visibility ?? undefined,
      },
      select: PROFILE_SELECT,
    });
    return this.hydrateProfile(profile);
  }

  async getProfile(viewerId: string, targetUserId: string) {
    await this.assertNotBlockedEitherWay(viewerId, targetUserId);

    const profile = await this.prisma.communityProfile.findUnique({
      where: { userId: targetUserId },
      select: PROFILE_SELECT,
    });
    if (!profile) {
      throw new NotFoundException('Community profile not found.');
    }

    const [postCount, followerCount, followingCount, isFollowedByViewer] = await Promise.all([
      this.prisma.communityPost.count({
        where: { authorId: targetUserId, moderationStatus: CommunityModerationStatus.APPROVED },
      }),
      this.prisma.communityFollow.count({ where: { followingId: targetUserId } }),
      this.prisma.communityFollow.count({ where: { followerId: targetUserId } }),
      viewerId === targetUserId
        ? Promise.resolve(false)
        : this.prisma.communityFollow
            .findUnique({
              where: {
                followerId_followingId: { followerId: viewerId, followingId: targetUserId },
              },
            })
            .then((f) => f != null),
    ]);

    if (viewerId !== targetUserId) {
      await this.assertProfileVisibleToViewer(viewerId, targetUserId, profile.visibility, {
        isFollowedByViewer,
      });
    }

    return {
      ...this.hydrateProfile(profile),
      postCount,
      followerCount,
      followingCount,
      isFollowedByViewer,
    };
  }

  // Same "not found, not forbidden" privacy pattern as
  // assertNotBlockedEitherWay — a private profile a viewer can't see
  // looks identical to one that doesn't exist.
  private async assertProfileVisibleToViewer(
    viewerId: string,
    targetUserId: string,
    visibility: CommunityProfileVisibility,
    context: { isFollowedByViewer: boolean },
  ): Promise<void> {
    if (visibility === 'PUBLIC') return;
    if (visibility === 'FOLLOWERS' && context.isFollowedByViewer) return;
    if (
      visibility === 'FRIENDS' &&
      (await this.friendsService.areFriends(viewerId, targetUserId))
    ) {
      return;
    }
    throw new NotFoundException('Community profile not found.');
  }

  private hydrateProfile(profile: ProfileSummary): HydratedProfile {
    const { avatarMediaAsset, coverMediaAsset, ...rest } = profile;
    return {
      ...rest,
      avatarUrl: avatarMediaAsset
        ? this.mediaService.getObjectUrl(avatarMediaAsset.storageKey)
        : rest.avatarUrl,
      coverUrl: coverMediaAsset ? this.mediaService.getObjectUrl(coverMediaAsset.storageKey) : null,
    };
  }

  // --- Posts --------------------------------------------------------------

  async createPost(userId: string, dto: CreateCommunityPostDto) {
    // Build Session 13 continuation Part C (Privacy Center) — an
    // omitted `visibility` used to silently fall through to the Prisma
    // column's own PUBLIC default, which no per-user preference could
    // ever override. Falls back to the caller's
    // Preference.defaultPostVisibility instead, applying to Reels
    // (mediaType VIDEO) exactly the same as text/image posts since both
    // share this one column.
    let visibility = dto.visibility;
    if (!visibility) {
      const preference = await this.prisma.preference.findUnique({
        where: { userId },
        select: { defaultPostVisibility: true },
      });
      visibility = preference?.defaultPostVisibility;
    }

    let mediaUrl = dto.mediaUrl;

    if (dto.mediaAssetId) {
      const asset = await this.mediaService.getById(userId, dto.mediaAssetId);
      if (asset.ownerId !== userId) {
        throw new NotFoundException('Media asset not found.');
      }
      if (asset.processingState !== 'READY') {
        throw new BadRequestException('This upload has not finished processing yet.');
      }
      if (asset.moderationState === 'REJECTED' || asset.moderationState === 'REMOVED') {
        throw new ForbiddenException('This media cannot be posted.');
      }
      // Post visibility is the real access gate at the API layer; the
      // underlying object just needs to be fetchable once the post is
      // anything other than fully private.
      await this.mediaService.setVisibility(
        userId,
        dto.mediaAssetId,
        visibility === CommunityVisibility.PRIVATE ? 'PRIVATE' : 'PUBLIC',
      );
      mediaUrl = this.mediaService.getObjectUrl(asset.storageKey);
    }

    const post = await this.prisma.communityPost.create({
      data: {
        authorId: userId,
        mediaType: dto.mediaType ?? undefined,
        mediaUrl,
        caption: dto.caption,
        visibility: visibility ?? undefined,
        isTrainerContent: dto.isTrainerContent ?? false,
      },
    });

    if (dto.mediaAssetId) {
      await this.mediaService.attachUsage(dto.mediaAssetId, 'COMMUNITY_POST', post.id);
    }

    return this.hydratePost(post, userId);
  }

  async listFeed(viewerId: string, query: QueryCommunityPostsDto) {
    const where = await this.buildVisibleWhere(viewerId, query.authorId, query.followingOnly);
    if (query.mediaType) {
      where.mediaType = query.mediaType;
    }

    const [posts, total] = await Promise.all([
      this.prisma.communityPost.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        ...paginationArgs(query),
      }),
      this.prisma.communityPost.count({ where }),
    ]);

    const hydrated = await this.hydratePosts(posts, viewerId);
    return { data: hydrated, meta: paginationMeta(query, total) };
  }

  async getPost(viewerId: string, postId: string) {
    const post = await this.findVisiblePost(viewerId, postId);
    return this.hydratePost(post, viewerId);
  }

  async deletePost(userId: string, postId: string): Promise<void> {
    const post = await this.prisma.communityPost.findUnique({ where: { id: postId } });
    if (!post) throw new NotFoundException('Post not found.');
    if (post.authorId !== userId) {
      throw new ForbiddenException('Only the author can delete this post.');
    }
    await this.prisma.communityPost.delete({ where: { id: postId } });
  }

  // --- Likes ----------------------------------------------------------------

  async like(userId: string, postId: string): Promise<void> {
    await this.findVisiblePost(userId, postId);
    await this.prisma.communityLike.upsert({
      where: { postId_userId: { postId, userId } },
      update: {},
      create: { postId, userId },
    });
  }

  async unlike(userId: string, postId: string): Promise<void> {
    await this.prisma.communityLike
      .delete({ where: { postId_userId: { postId, userId } } })
      .catch(ignoreNotFound);
  }

  // --- Saves ------------------------------------------------------------

  async save(userId: string, postId: string): Promise<void> {
    await this.findVisiblePost(userId, postId);
    await this.prisma.communitySave.upsert({
      where: { postId_userId: { postId, userId } },
      update: {},
      create: { postId, userId },
    });
  }

  async unsave(userId: string, postId: string): Promise<void> {
    await this.prisma.communitySave
      .delete({ where: { postId_userId: { postId, userId } } })
      .catch(ignoreNotFound);
  }

  async listSaved(userId: string, query: QueryCommunityPostsDto) {
    const [saves, total] = await Promise.all([
      this.prisma.communitySave.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        ...paginationArgs(query),
        include: { post: true },
      }),
      this.prisma.communitySave.count({ where: { userId } }),
    ]);
    const hydrated = await this.hydratePosts(
      saves.map((s) => s.post),
      userId,
    );
    return { data: hydrated, meta: paginationMeta(query, total) };
  }

  // --- Analytics ----------------------------------------------------------

  /**
   * A creator's own content performance — real, already-persisted
   * counts only (likes/comments/saves), aggregated across every post
   * they've ever made regardless of its current visibility or
   * moderation status, since it's for the author's own eyes. There is
   * no view/impression/reach tracking anywhere in the schema for
   * organic posts, so none is fabricated here — Ascend Promote's paid
   * impressions/clicks (PromoteService.getMetrics) are a deliberately
   * separate, per-campaign metric and are not blended in.
   */
  async getMyContentAnalytics(userId: string) {
    const posts = await this.prisma.communityPost.findMany({
      where: { authorId: userId },
      orderBy: { createdAt: 'desc' },
    });

    if (posts.length === 0) {
      return { totalPosts: 0, totalLikes: 0, totalComments: 0, totalSaves: 0, posts: [] };
    }

    const postIds = posts.map((p) => p.id);
    const [likeCounts, commentCounts, saveCounts] = await Promise.all([
      this.prisma.communityLike.groupBy({
        by: ['postId'],
        where: { postId: { in: postIds } },
        _count: true,
      }),
      this.prisma.communityComment.groupBy({
        by: ['postId'],
        where: { postId: { in: postIds } },
        _count: true,
      }),
      this.prisma.communitySave.groupBy({
        by: ['postId'],
        where: { postId: { in: postIds } },
        _count: true,
      }),
    ]);
    const likeCountByPost = new Map(likeCounts.map((c) => [c.postId, c._count]));
    const commentCountByPost = new Map(commentCounts.map((c) => [c.postId, c._count]));
    const saveCountByPost = new Map(saveCounts.map((c) => [c.postId, c._count]));

    const breakdown = posts
      .map((post) => {
        const likeCount = likeCountByPost.get(post.id) ?? 0;
        const commentCount = commentCountByPost.get(post.id) ?? 0;
        const saveCount = saveCountByPost.get(post.id) ?? 0;
        return {
          id: post.id,
          mediaType: post.mediaType,
          caption: post.caption,
          createdAt: post.createdAt,
          likeCount,
          commentCount,
          saveCount,
          engagementTotal: likeCount + commentCount + saveCount,
        };
      })
      .sort((a, b) => b.engagementTotal - a.engagementTotal);

    return {
      totalPosts: posts.length,
      totalLikes: breakdown.reduce((sum, p) => sum + p.likeCount, 0),
      totalComments: breakdown.reduce((sum, p) => sum + p.commentCount, 0),
      totalSaves: breakdown.reduce((sum, p) => sum + p.saveCount, 0),
      posts: breakdown,
    };
  }

  // --- Comments ---------------------------------------------------------

  async addComment(userId: string, postId: string, dto: CreateCommunityCommentDto) {
    await this.findVisiblePost(userId, postId);
    const comment = await this.prisma.communityComment.create({
      data: { postId, authorId: userId, body: dto.body },
    });
    return this.serializeComment(comment, await this.authorSummary(comment.authorId));
  }

  async listComments(viewerId: string, postId: string, query: QueryCommunityPostsDto) {
    await this.findVisiblePost(viewerId, postId);
    const [comments, total] = await Promise.all([
      this.prisma.communityComment.findMany({
        where: { postId },
        orderBy: { createdAt: 'asc' },
        ...paginationArgs(query),
      }),
      this.prisma.communityComment.count({ where: { postId } }),
    ]);
    const authorIds = [...new Set(comments.map((c) => c.authorId))];
    const profiles = await this.prisma.communityProfile.findMany({
      where: { userId: { in: authorIds } },
      select: PROFILE_SELECT,
    });
    const byAuthor = new Map(profiles.map((p) => [p.userId, this.hydrateProfile(p)]));
    return {
      data: comments.map((c) => this.serializeComment(c, byAuthor.get(c.authorId) ?? null)),
      meta: paginationMeta(query, total),
    };
  }

  async deleteComment(userId: string, commentId: string): Promise<void> {
    const comment = await this.prisma.communityComment.findUnique({ where: { id: commentId } });
    if (!comment) throw new NotFoundException('Comment not found.');
    const post = await this.prisma.communityPost.findUnique({ where: { id: comment.postId } });
    // The comment's own author, or the post's author moderating their
    // own post, may remove it — matches ordinary social-app behavior.
    const canDelete = comment.authorId === userId || post?.authorId === userId;
    if (!canDelete) {
      throw new ForbiddenException(
        'Only the comment author or post author can delete this comment.',
      );
    }
    await this.prisma.communityComment.delete({ where: { id: commentId } });
  }

  // --- Follows ------------------------------------------------------------

  async follow(followerId: string, followingId: string): Promise<void> {
    if (followerId === followingId) {
      throw new BadRequestException('You cannot follow yourself.');
    }
    await this.assertNotBlockedEitherWay(followerId, followingId);
    await this.prisma.communityFollow.upsert({
      where: { followerId_followingId: { followerId, followingId } },
      update: {},
      create: { followerId, followingId },
    });
  }

  async unfollow(followerId: string, followingId: string): Promise<void> {
    await this.prisma.communityFollow
      .delete({ where: { followerId_followingId: { followerId, followingId } } })
      .catch(ignoreNotFound);
  }

  async listFollowers(targetUserId: string, query: QueryCommunityPostsDto) {
    return this.listConnections({ followingId: targetUserId }, (f) => f.followerId, query);
  }

  async listFollowing(targetUserId: string, query: QueryCommunityPostsDto) {
    return this.listConnections({ followerId: targetUserId }, (f) => f.followingId, query);
  }

  private async listConnections(
    where: Prisma.CommunityFollowWhereInput,
    pickUserId: (f: { followerId: string; followingId: string }) => string,
    query: QueryCommunityPostsDto,
  ) {
    const [rows, total] = await Promise.all([
      this.prisma.communityFollow.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        ...paginationArgs(query),
      }),
      this.prisma.communityFollow.count({ where }),
    ]);
    const userIds = rows.map(pickUserId);
    const profiles = await this.prisma.communityProfile.findMany({
      where: { userId: { in: userIds } },
      select: PROFILE_SELECT,
    });
    const byUser = new Map(profiles.map((p) => [p.userId, this.hydrateProfile(p)]));
    return {
      data: userIds.map((id) => byUser.get(id) ?? { userId: id, displayName: null }),
      meta: paginationMeta(query, total),
    };
  }

  // --- Blocks -------------------------------------------------------------

  async block(blockerId: string, blockedId: string): Promise<void> {
    if (blockerId === blockedId) {
      throw new BadRequestException('You cannot block yourself.');
    }
    await this.prisma.$transaction([
      this.prisma.communityBlock.upsert({
        where: { blockerId_blockedId: { blockerId, blockedId } },
        update: {},
        create: { blockerId, blockedId },
      }),
      // Blocking severs any existing follow relationship in either
      // direction — a blocked user should not remain a "follower" of
      // record, and blocking must not leave the blocker still followed.
      this.prisma.communityFollow.deleteMany({
        where: {
          OR: [
            { followerId: blockerId, followingId: blockedId },
            { followerId: blockedId, followingId: blockerId },
          ],
        },
      }),
    ]);
    // Blocking also severs any friendship/pending friend request — a
    // block is a stronger signal than "not friends", it should never
    // leave a friendship record standing (Build Session 8 Part 7).
    await this.friendsService.severTies(blockerId, blockedId);
  }

  async unblock(blockerId: string, blockedId: string): Promise<void> {
    await this.prisma.communityBlock
      .delete({ where: { blockerId_blockedId: { blockerId, blockedId } } })
      .catch(ignoreNotFound);
  }

  /**
   * Every account the caller has blocked (Build Session 12 Part 12-14 —
   * Privacy Center) — the read side that `block`/`unblock` above never
   * had a way to surface, so a blocked user could previously only be
   * unblocked by revisiting the exact profile screen used to block
   * them.
   */
  async listBlocked(blockerId: string) {
    const blocks = await this.prisma.communityBlock.findMany({
      where: { blockerId },
      orderBy: { createdAt: 'desc' },
      include: { blocked: { include: { communityProfile: true } } },
    });
    return blocks.map((b) => ({
      userId: b.blockedId,
      displayName: b.blocked.communityProfile?.displayName ?? null,
      avatarUrl: b.blocked.communityProfile?.avatarUrl ?? null,
      blockedAt: b.createdAt,
    }));
  }

  // --- Reports --------------------------------------------------------

  async report(reporterId: string, dto: CreateCommunityReportDto) {
    await this.assertReportTargetExists(dto.targetType, dto.targetId);
    const report = await this.prisma.communityReport.create({
      data: {
        reporterId,
        targetType: dto.targetType,
        targetId: dto.targetId,
        reason: dto.reason,
      },
    });
    return { id: report.id, status: report.status, createdAt: report.createdAt };
  }

  private async assertReportTargetExists(targetType: string, targetId: string): Promise<void> {
    const exists =
      targetType === 'POST'
        ? await this.prisma.communityPost.findUnique({ where: { id: targetId } })
        : targetType === 'COMMENT'
          ? await this.prisma.communityComment.findUnique({ where: { id: targetId } })
          : await this.prisma.communityProfile.findUnique({ where: { userId: targetId } });
    if (!exists) {
      throw new NotFoundException('Report target not found.');
    }
  }

  // --- Shared helpers -----------------------------------------------------

  private async assertNotBlockedEitherWay(userId: string, otherUserId: string): Promise<void> {
    if (userId === otherUserId) return;
    const block = await this.prisma.communityBlock.findFirst({
      where: {
        OR: [
          { blockerId: userId, blockedId: otherUserId },
          { blockerId: otherUserId, blockedId: userId },
        ],
      },
    });
    if (block) {
      // Deliberately the same NotFoundException a nonexistent target
      // would raise — a block must not reveal to the blocked party that
      // they've been blocked (matches ordinary social-app behavior).
      throw new NotFoundException('Not found.');
    }
  }

  private async buildVisibleWhere(
    viewerId: string,
    authorIdFilter?: string,
    followingOnly?: boolean,
  ): Promise<Prisma.CommunityPostWhereInput> {
    const [blockedByViewer, blockingViewer, following] = await Promise.all([
      this.prisma.communityBlock.findMany({
        where: { blockerId: viewerId },
        select: { blockedId: true },
      }),
      this.prisma.communityBlock.findMany({
        where: { blockedId: viewerId },
        select: { blockerId: true },
      }),
      this.prisma.communityFollow.findMany({
        where: { followerId: viewerId },
        select: { followingId: true },
      }),
    ]);
    const excludedAuthorIds = [
      ...blockedByViewer.map((b) => b.blockedId),
      ...blockingViewer.map((b) => b.blockerId),
    ];
    const followingIds = following.map((f) => f.followingId);

    const visibilityOr: Prisma.CommunityPostWhereInput[] = [{ authorId: viewerId }];
    if (followingOnly) {
      // "Following" mode — only the caller's own posts plus anything by
      // someone they follow, regardless of that post's own PUBLIC/
      // FOLLOWERS visibility (both are fine to show a follower).
      if (followingIds.length > 0) {
        visibilityOr.push({
          visibility: { in: [CommunityVisibility.PUBLIC, CommunityVisibility.FOLLOWERS] },
          moderationStatus: CommunityModerationStatus.APPROVED,
          authorId: { in: followingIds },
        });
      }
    } else {
      // "Discover" mode (default) — own posts, any PUBLIC post, and
      // FOLLOWERS-only posts from people the caller follows.
      visibilityOr.push({
        visibility: CommunityVisibility.PUBLIC,
        moderationStatus: CommunityModerationStatus.APPROVED,
      });
      if (followingIds.length > 0) {
        visibilityOr.push({
          visibility: CommunityVisibility.FOLLOWERS,
          moderationStatus: CommunityModerationStatus.APPROVED,
          authorId: { in: followingIds },
        });
      }
    }

    return {
      AND: [
        excludedAuthorIds.length > 0 ? { authorId: { notIn: excludedAuthorIds } } : {},
        { OR: visibilityOr },
        ...(authorIdFilter ? [{ authorId: authorIdFilter }] : []),
      ],
    };
  }

  private async findVisiblePost(viewerId: string, postId: string): Promise<CommunityPost> {
    const post = await this.prisma.communityPost.findUnique({ where: { id: postId } });
    if (!post) throw new NotFoundException('Post not found.');
    if (post.authorId === viewerId) return post;

    await this.assertNotBlockedEitherWay(viewerId, post.authorId);

    if (post.moderationStatus !== CommunityModerationStatus.APPROVED) {
      throw new NotFoundException('Post not found.');
    }
    if (post.visibility === CommunityVisibility.PRIVATE) {
      throw new NotFoundException('Post not found.');
    }
    if (post.visibility === CommunityVisibility.FOLLOWERS) {
      const follows = await this.prisma.communityFollow.findUnique({
        where: { followerId_followingId: { followerId: viewerId, followingId: post.authorId } },
      });
      if (!follows) throw new NotFoundException('Post not found.');
    }
    return post;
  }

  private async authorSummary(userId: string) {
    const profile = await this.prisma.communityProfile.findUnique({
      where: { userId },
      select: PROFILE_SELECT,
    });
    return profile ? this.hydrateProfile(profile) : null;
  }

  private async hydratePost(post: CommunityPost, viewerId: string) {
    return (await this.hydratePosts([post], viewerId))[0];
  }

  private async hydratePosts(posts: CommunityPost[], viewerId: string) {
    if (posts.length === 0) return [];
    const postIds = posts.map((p) => p.id);
    const authorIds = [...new Set(posts.map((p) => p.authorId))];

    const [likeCounts, commentCounts, saveCounts, likedByViewer, savedByViewer, authorProfiles] =
      await Promise.all([
        this.prisma.communityLike.groupBy({
          by: ['postId'],
          where: { postId: { in: postIds } },
          _count: true,
        }),
        this.prisma.communityComment.groupBy({
          by: ['postId'],
          where: { postId: { in: postIds } },
          _count: true,
        }),
        this.prisma.communitySave.groupBy({
          by: ['postId'],
          where: { postId: { in: postIds } },
          _count: true,
        }),
        this.prisma.communityLike.findMany({
          where: { postId: { in: postIds }, userId: viewerId },
        }),
        this.prisma.communitySave.findMany({
          where: { postId: { in: postIds }, userId: viewerId },
        }),
        this.prisma.communityProfile.findMany({
          where: { userId: { in: authorIds } },
          select: PROFILE_SELECT,
        }),
      ]);

    const likeCountByPost = new Map(likeCounts.map((c) => [c.postId, c._count]));
    const commentCountByPost = new Map(commentCounts.map((c) => [c.postId, c._count]));
    const saveCountByPost = new Map(saveCounts.map((c) => [c.postId, c._count]));
    const likedPostIds = new Set(likedByViewer.map((l) => l.postId));
    const savedPostIds = new Set(savedByViewer.map((s) => s.postId));
    const profileByAuthor = new Map(authorProfiles.map((p) => [p.userId, this.hydrateProfile(p)]));

    return posts.map((post) => ({
      id: post.id,
      authorId: post.authorId,
      author: profileByAuthor.get(post.authorId) ?? null,
      mediaType: post.mediaType,
      mediaUrl: post.mediaUrl,
      caption: post.caption,
      visibility: post.visibility,
      moderationStatus: post.moderationStatus,
      isTrainerContent: post.isTrainerContent,
      likeCount: likeCountByPost.get(post.id) ?? 0,
      commentCount: commentCountByPost.get(post.id) ?? 0,
      saveCount: saveCountByPost.get(post.id) ?? 0,
      isLikedByViewer: likedPostIds.has(post.id),
      isSavedByViewer: savedPostIds.has(post.id),
      isOwnPost: post.authorId === viewerId,
      createdAt: post.createdAt,
      updatedAt: post.updatedAt,
    }));
  }

  private serializeComment(comment: CommunityComment, author: HydratedProfile | null) {
    return {
      id: comment.id,
      postId: comment.postId,
      authorId: comment.authorId,
      author,
      body: comment.body,
      createdAt: comment.createdAt,
    };
  }
}

function ignoreNotFound(error: unknown): void {
  if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2025') {
    return;
  }
  throw error;
}
