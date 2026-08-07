import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { FriendsService } from '../friends/friends.service';
import { MediaService } from '../media/media.service';
import { MessagesService } from './messages.service';

function conversation(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'conv-1',
    status: 'ACCEPTED',
    initiatorId: 'user-1',
    participants: [{ userId: 'user-1' }, { userId: 'user-2' }],
    ...overrides,
  };
}

describe('MessagesService', () => {
  let service: MessagesService;
  let prisma: {
    communityBlock: { findUnique: jest.Mock };
    user: { findUnique: jest.Mock };
    directConversation: {
      findFirst: jest.Mock;
      findUnique: jest.Mock;
      create: jest.Mock;
      update: jest.Mock;
    };
    directConversationParticipant: { findMany: jest.Mock; updateMany: jest.Mock };
    directMessage: {
      findMany: jest.Mock;
      findUnique: jest.Mock;
      create: jest.Mock;
      count: jest.Mock;
    };
    messageReceipt: { upsert: jest.Mock };
    messageReport: { create: jest.Mock };
    $transaction: jest.Mock;
  };
  let mediaService: { getById: jest.Mock; attachUsage: jest.Mock };
  let friendsService: { areFriends: jest.Mock };

  beforeEach(async () => {
    prisma = {
      communityBlock: { findUnique: jest.fn().mockResolvedValue(null) },
      user: { findUnique: jest.fn().mockResolvedValue({ id: 'user-2' }) },
      directConversation: {
        findFirst: jest.fn(),
        findUnique: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      directConversationParticipant: { findMany: jest.fn(), updateMany: jest.fn() },
      directMessage: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn(),
        create: jest.fn(),
        count: jest.fn(),
      },
      messageReceipt: { upsert: jest.fn() },
      messageReport: { create: jest.fn() },
      $transaction: jest.fn((ops: unknown[]) => Promise.all(ops)),
    };
    mediaService = { getById: jest.fn(), attachUsage: jest.fn() };
    friendsService = { areFriends: jest.fn().mockResolvedValue(false) };

    const moduleRef = await Test.createTestingModule({
      providers: [
        MessagesService,
        { provide: PrismaService, useValue: prisma },
        { provide: MediaService, useValue: mediaService },
        { provide: FriendsService, useValue: friendsService },
      ],
    }).compile();

    service = moduleRef.get(MessagesService);
  });

  describe('getOrCreateConversation', () => {
    it('rejects messaging yourself', async () => {
      await expect(service.getOrCreateConversation('user-1', 'user-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('404s when either side has blocked the other', async () => {
      prisma.communityBlock.findUnique
        .mockResolvedValueOnce({ blockerId: 'user-2', blockedId: 'user-1' })
        .mockResolvedValueOnce(null);

      await expect(service.getOrCreateConversation('user-1', 'user-2')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('reuses an existing conversation instead of creating a duplicate', async () => {
      const existing = conversation();
      prisma.directConversation.findFirst.mockResolvedValue(existing);

      const result = await service.getOrCreateConversation('user-1', 'user-2');

      expect(result).toBe(existing);
      expect(prisma.directConversation.create).not.toHaveBeenCalled();
    });

    it('creates an ACCEPTED conversation for friends', async () => {
      prisma.directConversation.findFirst.mockResolvedValue(null);
      friendsService.areFriends.mockResolvedValue(true);
      prisma.directConversation.create.mockResolvedValue(conversation());

      await service.getOrCreateConversation('user-1', 'user-2');

      expect(prisma.directConversation.create).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ status: 'ACCEPTED' }) }),
      );
    });

    it('creates a PENDING message request for non-friends', async () => {
      prisma.directConversation.findFirst.mockResolvedValue(null);
      friendsService.areFriends.mockResolvedValue(false);
      prisma.directConversation.create.mockResolvedValue(conversation({ status: 'PENDING' }));

      await service.getOrCreateConversation('user-1', 'user-2');

      expect(prisma.directConversation.create).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ status: 'PENDING' }) }),
      );
    });
  });

  describe('sendMessage', () => {
    it('404s when the caller is not a participant', async () => {
      prisma.directConversation.findUnique.mockResolvedValue(
        conversation({ participants: [{ userId: 'user-2' }, { userId: 'user-3' }] }),
      );
      await expect(service.sendMessage('user-1', 'conv-1', { body: 'hi' })).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('rejects sending into a DECLINED conversation', async () => {
      prisma.directConversation.findUnique.mockResolvedValue(conversation({ status: 'DECLINED' }));
      await expect(service.sendMessage('user-1', 'conv-1', { body: 'hi' })).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });

    it('rejects a second message from the initiator while still PENDING', async () => {
      prisma.directConversation.findUnique.mockResolvedValue(
        conversation({ status: 'PENDING', initiatorId: 'user-1' }),
      );
      prisma.directMessage.count.mockResolvedValue(1);

      await expect(
        service.sendMessage('user-1', 'conv-1', { body: 'hi again' }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects attachments from the initiator while still PENDING', async () => {
      prisma.directConversation.findUnique.mockResolvedValue(
        conversation({ status: 'PENDING', initiatorId: 'user-1' }),
      );
      prisma.directMessage.count.mockResolvedValue(0);

      await expect(
        service.sendMessage('user-1', 'conv-1', { mediaAssetIds: ['asset-1'] }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('accepts the conversation when the recipient replies while PENDING', async () => {
      prisma.directConversation.findUnique.mockResolvedValue(
        conversation({ status: 'PENDING', initiatorId: 'user-1' }),
      );
      prisma.directConversation.update.mockResolvedValue({});
      prisma.directMessage.create.mockResolvedValue({ id: 'msg-1', createdAt: new Date() });
      prisma.directConversationParticipant.updateMany.mockResolvedValue({});

      await service.sendMessage('user-2', 'conv-1', { body: 'sure, hi' });

      expect(prisma.directConversation.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: { status: 'ACCEPTED' } }),
      );
    });

    it("404s when an attachment doesn't belong to the sender", async () => {
      prisma.directConversation.findUnique.mockResolvedValue(conversation());
      mediaService.getById.mockResolvedValue({ ownerId: 'someone-else', processingState: 'READY' });

      await expect(
        service.sendMessage('user-1', 'conv-1', { mediaAssetIds: ['asset-1'] }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('creates a message and updates the conversation lastMessageAt', async () => {
      prisma.directConversation.findUnique.mockResolvedValue(conversation());
      prisma.directMessage.create.mockResolvedValue({ id: 'msg-1', createdAt: new Date() });
      prisma.directConversationParticipant.updateMany.mockResolvedValue({});

      const result = await service.sendMessage('user-1', 'conv-1', { body: 'hello' });

      expect(result.id).toBe('msg-1');
      expect(prisma.directConversation.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ lastMessageAt: expect.any(Date) }),
        }),
      );
    });
  });

  describe('acceptConversation / declineConversation', () => {
    it('rejects the initiator accepting their own request', async () => {
      prisma.directConversation.findUnique.mockResolvedValue(
        conversation({ status: 'PENDING', initiatorId: 'user-1' }),
      );
      await expect(service.acceptConversation('user-1', 'conv-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('rejects accepting a request that is no longer pending', async () => {
      prisma.directConversation.findUnique.mockResolvedValue(
        conversation({ status: 'ACCEPTED', initiatorId: 'user-1' }),
      );
      await expect(service.acceptConversation('user-2', 'conv-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('lets the recipient accept a pending request', async () => {
      prisma.directConversation.findUnique.mockResolvedValue(
        conversation({ status: 'PENDING', initiatorId: 'user-1' }),
      );
      prisma.directConversation.update.mockResolvedValue({ status: 'ACCEPTED' });

      const result = await service.acceptConversation('user-2', 'conv-1');

      expect(result.status).toBe('ACCEPTED');
    });

    it('lets the recipient decline a pending request', async () => {
      prisma.directConversation.findUnique.mockResolvedValue(
        conversation({ status: 'PENDING', initiatorId: 'user-1' }),
      );
      prisma.directConversation.update.mockResolvedValue({ status: 'DECLINED' });

      const result = await service.declineConversation('user-2', 'conv-1');

      expect(result.status).toBe('DECLINED');
    });
  });

  describe('reportMessage', () => {
    it('404s a message that does not exist', async () => {
      prisma.directMessage.findUnique.mockResolvedValue(null);

      await expect(
        service.reportMessage('user-1', 'missing', 'inappropriate'),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });
});
