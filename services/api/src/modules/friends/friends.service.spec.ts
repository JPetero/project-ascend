import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { FriendsService } from './friends.service';

describe('FriendsService', () => {
  let service: FriendsService;
  let prisma: {
    communityBlock: { findMany: jest.Mock; findUnique: jest.Mock };
    communityProfile: { findMany: jest.Mock };
    user: { findUnique: jest.Mock };
    friendRequest: {
      findFirst: jest.Mock;
      findUnique: jest.Mock;
      findMany: jest.Mock;
      create: jest.Mock;
      update: jest.Mock;
      updateMany: jest.Mock;
    };
    friendship: {
      findUnique: jest.Mock;
      findMany: jest.Mock;
      upsert: jest.Mock;
      delete: jest.Mock;
      deleteMany: jest.Mock;
      count: jest.Mock;
    };
    $transaction: jest.Mock;
  };

  beforeEach(async () => {
    prisma = {
      communityBlock: { findMany: jest.fn().mockResolvedValue([]), findUnique: jest.fn() },
      communityProfile: { findMany: jest.fn() },
      user: { findUnique: jest.fn() },
      friendRequest: {
        findFirst: jest.fn(),
        findUnique: jest.fn(),
        findMany: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
      },
      friendship: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        upsert: jest.fn(),
        delete: jest.fn(),
        deleteMany: jest.fn(),
        count: jest.fn(),
      },
      $transaction: jest.fn((ops: unknown[]) => Promise.all(ops)),
    };
    const notifications = { notify: jest.fn().mockResolvedValue(undefined) };

    const moduleRef = await Test.createTestingModule({
      providers: [
        FriendsService,
        { provide: PrismaService, useValue: prisma },
        { provide: NotificationsService, useValue: notifications },
      ],
    }).compile();

    service = moduleRef.get(FriendsService);
  });

  describe('sendRequest', () => {
    it('rejects sending a request to yourself', async () => {
      await expect(service.sendRequest('user-1', 'user-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('404s when the recipient has blocked the sender', async () => {
      prisma.communityBlock.findUnique
        .mockResolvedValueOnce({ blockerId: 'user-2', blockedId: 'user-1' })
        .mockResolvedValueOnce(null);

      await expect(service.sendRequest('user-1', 'user-2')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('404s when the recipient does not exist', async () => {
      prisma.communityBlock.findUnique.mockResolvedValue(null);
      prisma.user.findUnique.mockResolvedValue(null);

      await expect(service.sendRequest('user-1', 'user-2')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('rejects when already friends', async () => {
      prisma.communityBlock.findUnique.mockResolvedValue(null);
      prisma.user.findUnique.mockResolvedValue({ id: 'user-2' });
      prisma.friendship.findUnique.mockResolvedValue({ id: 'friendship-1' });

      await expect(service.sendRequest('user-1', 'user-2')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('rejects a duplicate pending request', async () => {
      prisma.communityBlock.findUnique.mockResolvedValue(null);
      prisma.user.findUnique.mockResolvedValue({ id: 'user-2' });
      prisma.friendship.findUnique.mockResolvedValue(null);
      prisma.friendRequest.findFirst
        .mockResolvedValueOnce(null) // no reciprocal
        .mockResolvedValueOnce({ id: 'existing' }); // already pending

      await expect(service.sendRequest('user-1', 'user-2')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('auto-accepts when the recipient already sent a pending request the other way', async () => {
      prisma.communityBlock.findUnique.mockResolvedValue(null);
      prisma.user.findUnique.mockResolvedValue({ id: 'user-2' });
      prisma.friendship.findUnique.mockResolvedValue(null);
      const reciprocal = {
        id: 'req-1',
        senderId: 'user-2',
        recipientId: 'user-1',
        status: 'PENDING',
      };
      prisma.friendRequest.findFirst.mockResolvedValueOnce(reciprocal);
      prisma.friendRequest.findUnique.mockResolvedValue(reciprocal);
      prisma.friendRequest.update.mockResolvedValue({});
      prisma.friendship.upsert.mockResolvedValue({ id: 'friendship-1' });

      const result = await service.sendRequest('user-1', 'user-2');

      expect(prisma.friendship.upsert).toHaveBeenCalled();
      expect(result).toEqual({ id: 'friendship-1' });
    });

    it('creates a new pending request when nothing conflicts', async () => {
      prisma.communityBlock.findUnique.mockResolvedValue(null);
      prisma.user.findUnique.mockResolvedValue({ id: 'user-2' });
      prisma.friendship.findUnique.mockResolvedValue(null);
      prisma.friendRequest.findFirst.mockResolvedValueOnce(null).mockResolvedValueOnce(null);
      prisma.friendRequest.create.mockResolvedValue({ id: 'req-1' });

      const result = await service.sendRequest('user-1', 'user-2');

      expect(prisma.friendRequest.create).toHaveBeenCalledWith({
        data: { senderId: 'user-1', recipientId: 'user-2' },
      });
      expect(result).toEqual({ id: 'req-1' });
    });
  });

  describe('acceptRequest', () => {
    it('404s a request that is not addressed to the caller', async () => {
      prisma.friendRequest.findUnique.mockResolvedValue({
        id: 'req-1',
        recipientId: 'someone-else',
        status: 'PENDING',
      });

      await expect(service.acceptRequest('user-1', 'req-1')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('rejects accepting an already-decided request', async () => {
      prisma.friendRequest.findUnique.mockResolvedValue({
        id: 'req-1',
        recipientId: 'user-1',
        senderId: 'user-2',
        status: 'DECLINED',
      });

      await expect(service.acceptRequest('user-1', 'req-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('creates a canonically-ordered friendship on success', async () => {
      prisma.friendRequest.findUnique.mockResolvedValue({
        id: 'req-1',
        senderId: 'user-2',
        recipientId: 'user-1',
        status: 'PENDING',
      });
      prisma.friendRequest.update.mockResolvedValue({});
      prisma.friendship.upsert.mockResolvedValue({ userAId: 'user-1', userBId: 'user-2' });

      await service.acceptRequest('user-1', 'req-1');

      expect(prisma.friendship.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { userAId_userBId: { userAId: 'user-1', userBId: 'user-2' } },
        }),
      );
    });
  });

  describe('cancelRequest', () => {
    it('404s a request the caller did not send', async () => {
      prisma.friendRequest.findUnique.mockResolvedValue({ id: 'req-1', senderId: 'someone-else' });
      await expect(service.cancelRequest('user-1', 'req-1')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('rejects canceling a request that is no longer pending', async () => {
      prisma.friendRequest.findUnique.mockResolvedValue({
        id: 'req-1',
        senderId: 'user-1',
        status: 'ACCEPTED',
      });
      await expect(service.cancelRequest('user-1', 'req-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });
  });

  describe('removeFriend', () => {
    it('404s when no friendship exists', async () => {
      prisma.friendship.delete.mockRejectedValue({ code: 'P2025' });
      await expect(service.removeFriend('user-1', 'user-2')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('deletes using the canonical pair ordering', async () => {
      prisma.friendship.delete.mockResolvedValue({});
      await service.removeFriend('user-2', 'user-1');
      expect(prisma.friendship.delete).toHaveBeenCalledWith({
        where: { userAId_userBId: { userAId: 'user-1', userBId: 'user-2' } },
      });
    });
  });

  describe('friendCount / listFriends', () => {
    it('counts friendships in either direction', async () => {
      prisma.friendship.count.mockResolvedValue(3);
      await expect(service.friendCount('user-1')).resolves.toBe(3);
      expect(prisma.friendship.count).toHaveBeenCalledWith({
        where: { OR: [{ userAId: 'user-1' }, { userBId: 'user-1' }] },
      });
    });

    it('returns an empty list with no extra query when there are no friendships', async () => {
      prisma.friendship.findMany.mockResolvedValue([]);
      await expect(service.listFriends('user-1')).resolves.toEqual([]);
      expect(prisma.communityProfile.findMany).not.toHaveBeenCalled();
    });
  });

  describe('severTies', () => {
    it('deletes the friendship and cancels any pending request in either direction', async () => {
      await service.severTies('user-2', 'user-1');

      expect(prisma.friendship.deleteMany).toHaveBeenCalledWith({
        where: { userAId: 'user-1', userBId: 'user-2' },
      });
      expect(prisma.friendRequest.updateMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ status: 'PENDING' }),
          data: expect.objectContaining({ status: 'CANCELED' }),
        }),
      );
    });
  });
});
