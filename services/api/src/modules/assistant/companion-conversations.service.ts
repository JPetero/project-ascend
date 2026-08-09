import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CompanionDto } from './assistant.types';
import {
  CompanionConversationDetail,
  CompanionConversationSummary,
} from './companion-conversations.types';

const MAX_TITLE_PREVIEW_LENGTH = 120;

/**
 * The raw chat transcript store (Build Session 12 Part 8) — deliberately
 * a separate table and a separate service from
 * `CompanionMemoryService`/`CompanionMemoryNote`. Memory is a handful of
 * extracted, structured facts the companion actively uses as context on
 * every turn; a conversation is the actual back-and-forth the user can
 * come back and re-read, gated on its own `Preference.
 * conversationHistoryEnabled` toggle. Deleting a conversation only ever
 * touches `CompanionConversation`/`CompanionChatMessage` rows —
 * `clearAll` and `deleteConversation` never reach `CompanionMemoryNote`
 * or `Preference`, and vice versa: `CompanionMemoryService.clear` never
 * reaches this table. `AssistantService` is the only caller, and only
 * ever after a successful reply.
 */
@Injectable()
export class CompanionConversationsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Appends the just-completed user/assistant turn, creating a new
   * conversation when `conversationId` is omitted or doesn't resolve to
   * one this user owns (e.g. it was deleted mid-conversation — silently
   * starting a new one is friendlier than erroring out on a reply the
   * user already received). Returns the conversation id the client
   * should send on the next turn to keep appending to the same thread.
   */
  async appendTurn(
    userId: string,
    params: {
      conversationId?: string;
      companion: CompanionDto;
      userText: string;
      assistantText: string;
    },
  ): Promise<string> {
    const existing = params.conversationId
      ? await this.prisma.companionConversation.findFirst({
          where: { id: params.conversationId, userId },
        })
      : null;

    const conversationId =
      existing?.id ??
      (
        await this.prisma.companionConversation.create({
          data: { userId, companion: params.companion },
        })
      ).id;

    await this.prisma.companionChatMessage.createMany({
      data: [
        { conversationId, isFromUser: true, text: params.userText },
        { conversationId, isFromUser: false, text: params.assistantText },
      ],
    });
    await this.prisma.companionConversation.update({
      where: { id: conversationId },
      data: { updatedAt: new Date() },
    });

    return conversationId;
  }

  async list(userId: string): Promise<CompanionConversationSummary[]> {
    const conversations = await this.prisma.companionConversation.findMany({
      where: { userId },
      orderBy: { updatedAt: 'desc' },
      include: { messages: { orderBy: { createdAt: 'desc' }, take: 1 } },
    });
    return conversations.map((conversation) => ({
      id: conversation.id,
      companion: conversation.companion as CompanionDto,
      title: conversation.title,
      createdAt: conversation.createdAt,
      updatedAt: conversation.updatedAt,
      lastMessagePreview: conversation.messages[0]?.text.slice(0, MAX_TITLE_PREVIEW_LENGTH) ?? null,
    }));
  }

  async get(userId: string, conversationId: string): Promise<CompanionConversationDetail> {
    const conversation = await this.prisma.companionConversation.findFirst({
      where: { id: conversationId, userId },
      include: { messages: { orderBy: { createdAt: 'asc' } } },
    });
    if (!conversation) {
      throw new NotFoundException('Conversation not found.');
    }
    return {
      id: conversation.id,
      companion: conversation.companion as CompanionDto,
      title: conversation.title,
      createdAt: conversation.createdAt,
      updatedAt: conversation.updatedAt,
      lastMessagePreview:
        conversation.messages.at(-1)?.text.slice(0, MAX_TITLE_PREVIEW_LENGTH) ?? null,
      messages: conversation.messages,
    };
  }

  async rename(userId: string, conversationId: string, title: string): Promise<void> {
    const result = await this.prisma.companionConversation.updateMany({
      where: { id: conversationId, userId },
      data: { title },
    });
    if (result.count === 0) {
      throw new NotFoundException('Conversation not found.');
    }
  }

  async delete(userId: string, conversationId: string): Promise<void> {
    const result = await this.prisma.companionConversation.deleteMany({
      where: { id: conversationId, userId },
    });
    if (result.count === 0) {
      throw new NotFoundException('Conversation not found.');
    }
  }

  async clearAll(userId: string): Promise<void> {
    await this.prisma.companionConversation.deleteMany({ where: { userId } });
  }
}
