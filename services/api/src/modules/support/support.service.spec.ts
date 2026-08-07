import { NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { SupportService } from './support.service';

function ticket(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'ticket-1',
    userId: 'user-1',
    category: 'BUG_REPORT',
    subject: 'Something broke',
    message: 'Details here',
    status: 'OPEN',
    createdAt: new Date('2026-08-07T00:00:00Z'),
    updatedAt: new Date('2026-08-07T00:00:00Z'),
    resolvedAt: null,
    ...overrides,
  };
}

describe('SupportService', () => {
  let service: SupportService;
  let prisma: {
    supportTicket: { create: jest.Mock; findMany: jest.Mock; findUnique: jest.Mock };
    supportTicketReply: { create: jest.Mock; findMany: jest.Mock };
  };

  beforeEach(async () => {
    prisma = {
      supportTicket: { create: jest.fn(), findMany: jest.fn(), findUnique: jest.fn() },
      supportTicketReply: { create: jest.fn(), findMany: jest.fn().mockResolvedValue([]) },
    };

    const moduleRef = await Test.createTestingModule({
      providers: [SupportService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = moduleRef.get(SupportService);
  });

  describe('create', () => {
    it('creates a ticket for the caller', async () => {
      prisma.supportTicket.create.mockResolvedValue(ticket());

      await service.create('user-1', {
        category: 'BUG_REPORT' as never,
        subject: 'Something broke',
        message: 'Details here',
      });

      expect(prisma.supportTicket.create).toHaveBeenCalledWith({
        data: {
          userId: 'user-1',
          category: 'BUG_REPORT',
          subject: 'Something broke',
          message: 'Details here',
        },
      });
    });
  });

  describe('getMine', () => {
    it('is not found for a ticket owned by someone else — never forbidden', async () => {
      prisma.supportTicket.findUnique.mockResolvedValue(ticket({ userId: 'someone-else' }));

      await expect(service.getMine('user-1', 'ticket-1')).rejects.toBeInstanceOf(NotFoundException);
    });

    it('returns the ticket with its replies for the owner', async () => {
      prisma.supportTicket.findUnique.mockResolvedValue(ticket());

      const result = await service.getMine('user-1', 'ticket-1');

      expect(result.id).toBe('ticket-1');
      expect(result.replies).toEqual([]);
    });
  });

  describe('addReply', () => {
    it('rejects a reply from a non-owner', async () => {
      prisma.supportTicket.findUnique.mockResolvedValue(ticket({ userId: 'someone-else' }));

      await expect(
        service.addReply('user-1', 'ticket-1', { body: 'follow-up' }),
      ).rejects.toBeInstanceOf(NotFoundException);
      expect(prisma.supportTicketReply.create).not.toHaveBeenCalled();
    });

    it('creates a non-staff reply for the owner', async () => {
      prisma.supportTicket.findUnique.mockResolvedValue(ticket());
      prisma.supportTicketReply.create.mockResolvedValue({
        id: 'reply-1',
        ticketId: 'ticket-1',
        authorId: 'user-1',
        isStaff: false,
        body: 'follow-up',
        createdAt: new Date(),
      });

      await service.addReply('user-1', 'ticket-1', { body: 'follow-up' });

      expect(prisma.supportTicketReply.create).toHaveBeenCalledWith({
        data: { ticketId: 'ticket-1', authorId: 'user-1', isStaff: false, body: 'follow-up' },
      });
    });
  });
});
