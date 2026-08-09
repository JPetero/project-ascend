import { NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CompanionDto } from './assistant.types';
import { CompanionConversationsService } from './companion-conversations.service';

function buildService() {
  const prisma = {
    companionConversation: {
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn().mockResolvedValue(undefined),
      updateMany: jest.fn(),
      deleteMany: jest.fn(),
      findMany: jest.fn(),
    },
    companionChatMessage: {
      createMany: jest.fn().mockResolvedValue(undefined),
    },
  } as unknown as PrismaService;
  return { service: new CompanionConversationsService(prisma), prisma };
}

describe('CompanionConversationsService', () => {
  describe('appendTurn', () => {
    it('creates a new conversation when no conversationId is given', async () => {
      const { service, prisma } = buildService();
      (prisma.companionConversation.create as jest.Mock).mockResolvedValue({ id: 'convo-1' });

      const id = await service.appendTurn('user-1', {
        companion: CompanionDto.ATLAS,
        userText: 'hello',
        assistantText: 'hi there',
      });

      expect(id).toBe('convo-1');
      expect(prisma.companionConversation.create).toHaveBeenCalledWith({
        data: { userId: 'user-1', companion: CompanionDto.ATLAS },
      });
      expect(prisma.companionChatMessage.createMany).toHaveBeenCalledWith({
        data: [
          { conversationId: 'convo-1', isFromUser: true, text: 'hello' },
          { conversationId: 'convo-1', isFromUser: false, text: 'hi there' },
        ],
      });
    });

    it('appends to an existing conversation this user owns instead of creating a new one', async () => {
      const { service, prisma } = buildService();
      (prisma.companionConversation.findFirst as jest.Mock).mockResolvedValue({ id: 'convo-1' });

      const id = await service.appendTurn('user-1', {
        conversationId: 'convo-1',
        companion: CompanionDto.ATLAS,
        userText: 'more',
        assistantText: 'reply',
      });

      expect(id).toBe('convo-1');
      expect(prisma.companionConversation.findFirst).toHaveBeenCalledWith({
        where: { id: 'convo-1', userId: 'user-1' },
      });
      expect(prisma.companionConversation.create).not.toHaveBeenCalled();
    });

    it('silently starts a fresh conversation instead of erroring when the given conversationId does not resolve to one this user owns', async () => {
      const { service, prisma } = buildService();
      (prisma.companionConversation.findFirst as jest.Mock).mockResolvedValue(null);
      (prisma.companionConversation.create as jest.Mock).mockResolvedValue({ id: 'convo-new' });

      const id = await service.appendTurn('user-1', {
        conversationId: 'someone-elses-convo',
        companion: CompanionDto.NOVA,
        userText: 'hi',
        assistantText: 'hey',
      });

      expect(id).toBe('convo-new');
      expect(prisma.companionConversation.create).toHaveBeenCalled();
    });
  });

  describe('list', () => {
    it('maps each conversation to a summary with its most recent message as a preview', async () => {
      const { service, prisma } = buildService();
      (prisma.companionConversation.findMany as jest.Mock).mockResolvedValue([
        {
          id: 'convo-1',
          companion: CompanionDto.ATLAS,
          title: null,
          createdAt: new Date('2026-01-01'),
          updatedAt: new Date('2026-01-02'),
          messages: [{ text: 'latest message' }],
        },
      ]);

      const summaries = await service.list('user-1');

      expect(summaries).toEqual([
        {
          id: 'convo-1',
          companion: CompanionDto.ATLAS,
          title: null,
          createdAt: new Date('2026-01-01'),
          updatedAt: new Date('2026-01-02'),
          lastMessagePreview: 'latest message',
        },
      ]);
      expect(prisma.companionConversation.findMany).toHaveBeenCalledWith({
        where: { userId: 'user-1' },
        orderBy: { updatedAt: 'desc' },
        include: { messages: { orderBy: { createdAt: 'desc' }, take: 1 } },
      });
    });

    it('never queries another user — always scoped by userId', async () => {
      const { service, prisma } = buildService();
      (prisma.companionConversation.findMany as jest.Mock).mockResolvedValue([]);

      await service.list('user-1');

      expect(prisma.companionConversation.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { userId: 'user-1' } }),
      );
    });
  });

  describe('get', () => {
    it('returns the full ordered transcript for a conversation this user owns', async () => {
      const { service, prisma } = buildService();
      (prisma.companionConversation.findFirst as jest.Mock).mockResolvedValue({
        id: 'convo-1',
        companion: CompanionDto.NOVA,
        title: 'My chat',
        createdAt: new Date('2026-01-01'),
        updatedAt: new Date('2026-01-02'),
        messages: [{ text: 'hi' }, { text: 'hello!' }],
      });

      const detail = await service.get('user-1', 'convo-1');

      expect(detail.messages).toEqual([{ text: 'hi' }, { text: 'hello!' }]);
      expect(detail.lastMessagePreview).toBe('hello!');
    });

    it('404s for a conversation belonging to someone else or that does not exist', async () => {
      const { service, prisma } = buildService();
      (prisma.companionConversation.findFirst as jest.Mock).mockResolvedValue(null);

      await expect(service.get('user-1', 'not-mine')).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  describe('rename', () => {
    it('renames a conversation this user owns', async () => {
      const { service, prisma } = buildService();
      (prisma.companionConversation.updateMany as jest.Mock).mockResolvedValue({ count: 1 });

      await service.rename('user-1', 'convo-1', 'Leg day planning');

      expect(prisma.companionConversation.updateMany).toHaveBeenCalledWith({
        where: { id: 'convo-1', userId: 'user-1' },
        data: { title: 'Leg day planning' },
      });
    });

    it('404s renaming a conversation belonging to someone else', async () => {
      const { service, prisma } = buildService();
      (prisma.companionConversation.updateMany as jest.Mock).mockResolvedValue({ count: 0 });

      await expect(service.rename('user-1', 'not-mine', 'New title')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });

  describe('delete', () => {
    it('deletes a conversation this user owns', async () => {
      const { service, prisma } = buildService();
      (prisma.companionConversation.deleteMany as jest.Mock).mockResolvedValue({ count: 1 });

      await service.delete('user-1', 'convo-1');

      expect(prisma.companionConversation.deleteMany).toHaveBeenCalledWith({
        where: { id: 'convo-1', userId: 'user-1' },
      });
    });

    it('404s deleting a conversation belonging to someone else', async () => {
      const { service, prisma } = buildService();
      (prisma.companionConversation.deleteMany as jest.Mock).mockResolvedValue({ count: 0 });

      await expect(service.delete('user-1', 'not-mine')).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  describe('clearAll', () => {
    it('deletes every conversation for this user, scoped by userId', async () => {
      const { service, prisma } = buildService();

      await service.clearAll('user-1');

      expect(prisma.companionConversation.deleteMany).toHaveBeenCalledWith({
        where: { userId: 'user-1' },
      });
    });
  });
});
