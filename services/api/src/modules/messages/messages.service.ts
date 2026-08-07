import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DirectConversationStatus, DirectMessageType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { FriendsService } from '../friends/friends.service';
import { MediaService } from '../media/media.service';
import { SendMessageDto } from './dto/send-message.dto';

/**
 * Direct Messaging (Build Session 8 Part 8) — database-first, real-time
 * delivery is a convenience layer on top (see messages.gateway.ts), never
 * a requirement for durability. A conversation with someone the caller
 * isn't friends with starts as a "message request" (PENDING): the
 * initiator gets exactly one message before the recipient responds,
 * which is how attachment spam is actually prevented rather than just
 * documented.
 */
@Injectable()
export class MessagesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly mediaService: MediaService,
    private readonly friendsService: FriendsService,
  ) {}

  async getOrCreateConversation(userId: string, recipientId: string) {
    if (userId === recipientId) {
      throw new BadRequestException('You cannot message yourself.');
    }

    const [blockedByRecipient, blockedByMe, recipient] = await Promise.all([
      this.prisma.communityBlock.findUnique({
        where: { blockerId_blockedId: { blockerId: recipientId, blockedId: userId } },
      }),
      this.prisma.communityBlock.findUnique({
        where: { blockerId_blockedId: { blockerId: userId, blockedId: recipientId } },
      }),
      this.prisma.user.findUnique({ where: { id: recipientId } }),
    ]);
    if (blockedByRecipient || blockedByMe || !recipient) {
      throw new NotFoundException('User not found.');
    }

    const existing = await this.prisma.directConversation.findFirst({
      where: {
        participants: { every: { userId: { in: [userId, recipientId] } } },
        AND: [
          { participants: { some: { userId } } },
          { participants: { some: { userId: recipientId } } },
        ],
      },
      include: { participants: true },
    });
    if (existing) return existing;

    const areFriends = await this.friendsService.areFriends(userId, recipientId);
    return this.prisma.directConversation.create({
      data: {
        initiatorId: userId,
        status: areFriends ? DirectConversationStatus.ACCEPTED : DirectConversationStatus.PENDING,
        participants: {
          create: [{ userId }, { userId: recipientId }],
        },
      },
      include: { participants: true },
    });
  }

  async listConversations(userId: string) {
    const participations = await this.prisma.directConversationParticipant.findMany({
      where: { userId, deletedAt: null },
      include: {
        conversation: {
          include: {
            participants: true,
            messages: { orderBy: { createdAt: 'desc' }, take: 1 },
          },
        },
      },
      orderBy: { conversation: { lastMessageAt: 'desc' } },
    });

    return Promise.all(
      participations.map(async (participation) => {
        const conversation = participation.conversation;
        const otherParticipant = conversation.participants.find((p) => p.userId !== userId);
        const unreadCount = await this.prisma.directMessage.count({
          where: {
            conversationId: conversation.id,
            senderId: { not: userId },
            deletedAt: null,
            createdAt: { gt: participation.lastReadAt ?? new Date(0) },
          },
        });
        return {
          id: conversation.id,
          status: conversation.status,
          initiatorId: conversation.initiatorId,
          otherUserId: otherParticipant?.userId ?? null,
          lastMessage: conversation.messages[0] ?? null,
          unreadCount,
          isMuted: participation.mutedAt !== null,
        };
      }),
    );
  }

  async unreadCount(userId: string): Promise<number> {
    const conversations = await this.listConversations(userId);
    return conversations.reduce((sum, c) => sum + c.unreadCount, 0);
  }

  async getMessages(userId: string, conversationId: string, page = 1, limit = 30) {
    await this.assertParticipant(userId, conversationId);

    const messages = await this.prisma.directMessage.findMany({
      where: { conversationId, deletedAt: null },
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
      include: { attachments: { include: { mediaAsset: true } } },
    });

    // Any message from the other participant that this caller has now
    // fetched is, by definition, delivered.
    const undelivered = messages.filter((m) => m.senderId !== userId);
    if (undelivered.length > 0) {
      await this.prisma.$transaction(
        undelivered.map((m) =>
          this.prisma.messageReceipt.upsert({
            where: { messageId_userId_status: { messageId: m.id, userId, status: 'DELIVERED' } },
            update: {},
            create: { messageId: m.id, userId, status: 'DELIVERED' },
          }),
        ),
      );
    }

    return messages;
  }

  async sendMessage(userId: string, conversationId: string, dto: SendMessageDto) {
    const conversation = await this.assertParticipant(userId, conversationId);

    if (conversation.status === DirectConversationStatus.DECLINED) {
      throw new ForbiddenException('This conversation was declined.');
    }

    if (conversation.status === DirectConversationStatus.PENDING) {
      if (userId === conversation.initiatorId) {
        const alreadySent = await this.prisma.directMessage.count({
          where: { conversationId, senderId: userId },
        });
        if (alreadySent >= 1) {
          throw new BadRequestException(
            'Wait for a response before sending another message request.',
          );
        }
        if (dto.mediaAssetIds?.length) {
          throw new BadRequestException('Attachments require an accepted conversation.');
        }
      } else {
        // The recipient responding is treated as accepting the request.
        await this.prisma.directConversation.update({
          where: { id: conversationId },
          data: { status: DirectConversationStatus.ACCEPTED },
        });
      }
    }

    if (dto.mediaAssetIds?.length) {
      for (const mediaAssetId of dto.mediaAssetIds) {
        const asset = await this.mediaService.getById(userId, mediaAssetId);
        if (asset.ownerId !== userId) throw new NotFoundException('Media asset not found.');
        if (asset.processingState !== 'READY') {
          throw new BadRequestException('An attachment has not finished uploading yet.');
        }
      }
    }

    const message = await this.prisma.directMessage.create({
      data: {
        conversationId,
        senderId: userId,
        type: dto.type ?? DirectMessageType.TEXT,
        body: dto.body,
        replyToId: dto.replyToId,
        sharedReferenceId: dto.sharedReferenceId,
        attachments: dto.mediaAssetIds?.length
          ? { create: dto.mediaAssetIds.map((mediaAssetId) => ({ mediaAssetId })) }
          : undefined,
      },
      include: { attachments: { include: { mediaAsset: true } } },
    });

    await Promise.all([
      this.prisma.directConversation.update({
        where: { id: conversationId },
        data: { lastMessageAt: message.createdAt },
      }),
      this.prisma.directConversationParticipant.updateMany({
        where: { conversationId, userId: { not: userId } },
        data: { deletedAt: null },
      }),
      ...(dto.mediaAssetIds ?? []).map((mediaAssetId) =>
        this.mediaService.attachUsage(mediaAssetId, 'CHAT_MESSAGE', message.id),
      ),
    ]);

    return message;
  }

  async markRead(userId: string, conversationId: string): Promise<void> {
    await this.assertParticipant(userId, conversationId);
    const now = new Date();
    const unread = await this.prisma.directMessage.findMany({
      where: { conversationId, senderId: { not: userId }, createdAt: { lte: now } },
      select: { id: true },
    });
    await this.prisma.$transaction([
      this.prisma.directConversationParticipant.updateMany({
        where: { conversationId, userId },
        data: { lastReadAt: now },
      }),
      ...unread.map((m) =>
        this.prisma.messageReceipt.upsert({
          where: { messageId_userId_status: { messageId: m.id, userId, status: 'READ' } },
          update: {},
          create: { messageId: m.id, userId, status: 'READ' },
        }),
      ),
    ]);
  }

  async setMuted(userId: string, conversationId: string, muted: boolean): Promise<void> {
    await this.assertParticipant(userId, conversationId);
    await this.prisma.directConversationParticipant.updateMany({
      where: { conversationId, userId },
      data: { mutedAt: muted ? new Date() : null },
    });
  }

  async deleteForSelf(userId: string, conversationId: string): Promise<void> {
    await this.assertParticipant(userId, conversationId);
    await this.prisma.directConversationParticipant.updateMany({
      where: { conversationId, userId },
      data: { deletedAt: new Date() },
    });
  }

  async acceptConversation(userId: string, conversationId: string) {
    const conversation = await this.assertParticipant(userId, conversationId);
    if (conversation.initiatorId === userId) {
      throw new BadRequestException('You cannot accept your own message request.');
    }
    if (conversation.status !== DirectConversationStatus.PENDING) {
      throw new BadRequestException('This request is no longer pending.');
    }
    return this.prisma.directConversation.update({
      where: { id: conversationId },
      data: { status: DirectConversationStatus.ACCEPTED },
    });
  }

  async declineConversation(userId: string, conversationId: string) {
    const conversation = await this.assertParticipant(userId, conversationId);
    if (conversation.initiatorId === userId) {
      throw new BadRequestException('You cannot decline your own message request.');
    }
    if (conversation.status !== DirectConversationStatus.PENDING) {
      throw new BadRequestException('This request is no longer pending.');
    }
    return this.prisma.directConversation.update({
      where: { id: conversationId },
      data: { status: DirectConversationStatus.DECLINED },
    });
  }

  async reportMessage(reporterId: string, messageId: string, reason: string) {
    const message = await this.prisma.directMessage.findUnique({ where: { id: messageId } });
    if (!message) throw new NotFoundException('Message not found.');
    await this.assertParticipant(reporterId, message.conversationId);

    return this.prisma.messageReport.create({
      data: { messageId, reporterId, reason },
    });
  }

  private async assertParticipant(userId: string, conversationId: string) {
    const conversation = await this.prisma.directConversation.findUnique({
      where: { id: conversationId },
      include: { participants: true },
    });
    if (!conversation || !conversation.participants.some((p) => p.userId === userId)) {
      throw new NotFoundException('Conversation not found.');
    }
    return conversation;
  }
}
