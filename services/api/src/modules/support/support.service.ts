import { Injectable, NotFoundException } from '@nestjs/common';
import { SupportTicket, SupportTicketReply } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AddReplyDto } from './dto/add-reply.dto';
import { CreateTicketDto } from './dto/create-ticket.dto';

/**
 * Support — Founder Scenario 27. Every category here (help center
 * follow-up, bug reports, safety reports, accessibility feedback,
 * account recovery, billing help, moderation appeals) is free on every
 * tier; nothing in this module checks `AppCapability.SUPPORT_ACCESS`
 * because it's never gated — the JWT auth guard alone is the only
 * check, same as every other free-tier endpoint in this app.
 */
@Injectable()
export class SupportService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, dto: CreateTicketDto) {
    const ticket = await this.prisma.supportTicket.create({
      data: { userId, category: dto.category, subject: dto.subject, message: dto.message },
    });
    return this.serializeTicket(ticket);
  }

  async listMine(userId: string) {
    const tickets = await this.prisma.supportTicket.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
    return tickets.map((t) => this.serializeTicket(t));
  }

  async getMine(userId: string, id: string) {
    const ticket = await this.findOwnedTicket(userId, id);
    const replies = await this.prisma.supportTicketReply.findMany({
      where: { ticketId: id },
      orderBy: { createdAt: 'asc' },
    });
    return { ...this.serializeTicket(ticket), replies: replies.map((r) => this.serializeReply(r)) };
  }

  async addReply(userId: string, id: string, dto: AddReplyDto) {
    await this.findOwnedTicket(userId, id);
    const reply = await this.prisma.supportTicketReply.create({
      data: { ticketId: id, authorId: userId, isStaff: false, body: dto.body },
    });
    return this.serializeReply(reply);
  }

  private async findOwnedTicket(userId: string, id: string): Promise<SupportTicket> {
    const ticket = await this.prisma.supportTicket.findUnique({ where: { id } });
    // Not found rather than forbidden for a ticket owned by someone
    // else — same privacy pattern used throughout this app (Community's
    // blocked-user checks, Trainer Groups' membership checks).
    if (!ticket || ticket.userId !== userId) {
      throw new NotFoundException('Support ticket not found.');
    }
    return ticket;
  }

  private serializeTicket(ticket: SupportTicket) {
    return {
      id: ticket.id,
      userId: ticket.userId,
      category: ticket.category,
      subject: ticket.subject,
      message: ticket.message,
      status: ticket.status,
      createdAt: ticket.createdAt,
      updatedAt: ticket.updatedAt,
      resolvedAt: ticket.resolvedAt,
    };
  }

  private serializeReply(reply: SupportTicketReply) {
    return {
      id: reply.id,
      ticketId: reply.ticketId,
      authorId: reply.authorId,
      isStaff: reply.isStaff,
      body: reply.body,
      createdAt: reply.createdAt,
    };
  }
}
