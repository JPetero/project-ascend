import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { FriendRequestStatus, NotificationType } from '@prisma/client';
import { canonicalFriendPair } from '../../common/friendship/friendship-pair.util';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

const PROFILE_SELECT = {
  userId: true,
  displayName: true,
  bio: true,
  avatarUrl: true,
  isTrainer: true,
} as const;

/**
 * Real mutual friendships (Build Session 8 Part 7) — deliberately
 * separate from Community's one-directional Follow (see schema.prisma's
 * doc comment on Friendship). A Friendship gates direct-message
 * "friend" status (Part 8, no message-request limits) and friend-only
 * joint workout invites (Part 9).
 */
@Injectable()
export class FriendsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

  async searchUsers(viewerId: string, query: string) {
    const [blockedByViewer, blockingViewer] = await Promise.all([
      this.prisma.communityBlock.findMany({
        where: { blockerId: viewerId },
        select: { blockedId: true },
      }),
      this.prisma.communityBlock.findMany({
        where: { blockedId: viewerId },
        select: { blockerId: true },
      }),
    ]);
    const excludedIds = [
      viewerId,
      ...blockedByViewer.map((b) => b.blockedId),
      ...blockingViewer.map((b) => b.blockerId),
    ];

    const profiles = await this.prisma.communityProfile.findMany({
      where: {
        displayName: { contains: query, mode: 'insensitive' },
        userId: { notIn: excludedIds },
      },
      select: PROFILE_SELECT,
      take: 20,
    });

    // Batched — was 2 queries per matched profile
    // (Promise.all(profiles.map(async ... areFriends/findActiveRequestBetween)))
    // on this type-ahead search's hot path (Build Session 12 Part 27-32).
    const candidateIds = profiles.map((p) => p.userId);
    const [friendships, pendingRequests] = await Promise.all([
      this.prisma.friendship.findMany({
        where: {
          OR: [
            { userAId: viewerId, userBId: { in: candidateIds } },
            { userBId: viewerId, userAId: { in: candidateIds } },
          ],
        },
      }),
      this.prisma.friendRequest.findMany({
        where: {
          status: FriendRequestStatus.PENDING,
          OR: [
            { senderId: viewerId, recipientId: { in: candidateIds } },
            { recipientId: viewerId, senderId: { in: candidateIds } },
          ],
        },
      }),
    ]);
    const friendUserIds = new Set(
      friendships.map((f) => (f.userAId === viewerId ? f.userBId : f.userAId)),
    );
    const pendingRequestByUser = new Map(
      pendingRequests.map((r) => [r.senderId === viewerId ? r.recipientId : r.senderId, r]),
    );

    return profiles.map((profile) => ({
      ...profile,
      isFriend: friendUserIds.has(profile.userId),
      pendingRequest: pendingRequestByUser.get(profile.userId) ?? null,
    }));
  }

  async sendRequest(senderId: string, recipientId: string) {
    if (senderId === recipientId) {
      throw new BadRequestException('You cannot send a friend request to yourself.');
    }

    const [blockedByRecipient, blockedByMe, recipient] = await Promise.all([
      this.prisma.communityBlock.findUnique({
        where: { blockerId_blockedId: { blockerId: recipientId, blockedId: senderId } },
      }),
      this.prisma.communityBlock.findUnique({
        where: { blockerId_blockedId: { blockerId: senderId, blockedId: recipientId } },
      }),
      this.prisma.user.findUnique({ where: { id: recipientId } }),
    ]);
    if (blockedByRecipient || blockedByMe || !recipient) {
      throw new NotFoundException('User not found.');
    }

    if (await this.areFriends(senderId, recipientId)) {
      throw new BadRequestException('You are already friends.');
    }

    // A reciprocal pending request from the other person is treated as
    // mutual interest — accept it instead of creating a second, opposite
    // request that would otherwise sit unanswered forever.
    const reciprocal = await this.prisma.friendRequest.findFirst({
      where: { senderId: recipientId, recipientId: senderId, status: FriendRequestStatus.PENDING },
    });
    if (reciprocal) {
      return this.acceptRequest(senderId, reciprocal.id);
    }

    const existing = await this.prisma.friendRequest.findFirst({
      where: { senderId, recipientId, status: FriendRequestStatus.PENDING },
    });
    if (existing) {
      throw new BadRequestException('A friend request to this person is already pending.');
    }

    const request = await this.prisma.friendRequest.create({ data: { senderId, recipientId } });
    await this.notifications.notify(
      recipientId,
      NotificationType.FRIEND_REQUEST,
      'New friend request',
      'Someone sent you a friend request.',
      request.id,
    );
    return request;
  }

  async acceptRequest(userId: string, requestId: string) {
    const request = await this.findOwnedIncomingPending(userId, requestId);
    const pair = canonicalFriendPair(request.senderId, request.recipientId);
    const [, friendship] = await this.prisma.$transaction([
      this.prisma.friendRequest.update({
        where: { id: requestId },
        data: { status: FriendRequestStatus.ACCEPTED, respondedAt: new Date() },
      }),
      this.prisma.friendship.upsert({
        where: { userAId_userBId: pair },
        update: {},
        create: pair,
      }),
    ]);
    return friendship;
  }

  async declineRequest(userId: string, requestId: string) {
    await this.findOwnedIncomingPending(userId, requestId);
    return this.prisma.friendRequest.update({
      where: { id: requestId },
      data: { status: FriendRequestStatus.DECLINED, respondedAt: new Date() },
    });
  }

  async cancelRequest(userId: string, requestId: string) {
    const request = await this.prisma.friendRequest.findUnique({ where: { id: requestId } });
    if (!request || request.senderId !== userId) {
      throw new NotFoundException('Friend request not found.');
    }
    if (request.status !== FriendRequestStatus.PENDING) {
      throw new BadRequestException('Only a pending request can be canceled.');
    }
    return this.prisma.friendRequest.update({
      where: { id: requestId },
      data: { status: FriendRequestStatus.CANCELED, respondedAt: new Date() },
    });
  }

  async removeFriend(userId: string, friendId: string): Promise<void> {
    const pair = canonicalFriendPair(userId, friendId);
    await this.prisma.friendship
      .delete({ where: { userAId_userBId: pair } })
      .catch((error: { code?: string }) => {
        if (error?.code !== 'P2025') throw error;
        throw new NotFoundException('You are not friends with this person.');
      });
  }

  async listFriends(userId: string) {
    const friendships = await this.prisma.friendship.findMany({
      where: { OR: [{ userAId: userId }, { userBId: userId }] },
      orderBy: { createdAt: 'desc' },
    });
    const friendIds = friendships.map((f) => (f.userAId === userId ? f.userBId : f.userAId));
    if (friendIds.length === 0) return [];
    const profiles = await this.prisma.communityProfile.findMany({
      where: { userId: { in: friendIds } },
      select: PROFILE_SELECT,
    });
    const byId = new Map(profiles.map((p) => [p.userId, p]));
    return friendIds.map(
      (id) =>
        byId.get(id) ?? {
          userId: id,
          displayName: 'Ascend member',
          bio: null,
          avatarUrl: null,
          isTrainer: false,
        },
    );
  }

  async friendCount(userId: string): Promise<number> {
    return this.prisma.friendship.count({
      where: { OR: [{ userAId: userId }, { userBId: userId }] },
    });
  }

  async listIncomingRequests(userId: string) {
    return this.prisma.friendRequest.findMany({
      where: { recipientId: userId, status: FriendRequestStatus.PENDING },
      orderBy: { createdAt: 'desc' },
    });
  }

  async listOutgoingRequests(userId: string) {
    return this.prisma.friendRequest.findMany({
      where: { senderId: userId, status: FriendRequestStatus.PENDING },
      orderBy: { createdAt: 'desc' },
    });
  }

  async areFriends(userIdA: string, userIdB: string): Promise<boolean> {
    const pair = canonicalFriendPair(userIdA, userIdB);
    const friendship = await this.prisma.friendship.findUnique({
      where: { userAId_userBId: pair },
    });
    return !!friendship;
  }

  /** Deletes any friendship and cancels any pending request between two users — called when one blocks the other. */
  async severTies(userIdA: string, userIdB: string): Promise<void> {
    const pair = canonicalFriendPair(userIdA, userIdB);
    await this.prisma.$transaction([
      this.prisma.friendship.deleteMany({ where: pair }),
      this.prisma.friendRequest.updateMany({
        where: {
          status: FriendRequestStatus.PENDING,
          OR: [
            { senderId: userIdA, recipientId: userIdB },
            { senderId: userIdB, recipientId: userIdA },
          ],
        },
        data: { status: FriendRequestStatus.CANCELED, respondedAt: new Date() },
      }),
    ]);
  }

  private async findActiveRequestBetween(userIdA: string, userIdB: string) {
    return this.prisma.friendRequest.findFirst({
      where: {
        status: FriendRequestStatus.PENDING,
        OR: [
          { senderId: userIdA, recipientId: userIdB },
          { senderId: userIdB, recipientId: userIdA },
        ],
      },
    });
  }

  private async findOwnedIncomingPending(userId: string, requestId: string) {
    const request = await this.prisma.friendRequest.findUnique({ where: { id: requestId } });
    if (!request || request.recipientId !== userId) {
      throw new NotFoundException('Friend request not found.');
    }
    if (request.status !== FriendRequestStatus.PENDING) {
      throw new BadRequestException('This request is no longer pending.');
    }
    return request;
  }
}
