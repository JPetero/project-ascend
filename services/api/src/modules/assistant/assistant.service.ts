import { Inject, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CompanionMemoryService } from './companion-memory.service';
import { AssistantReplyDto } from './dto/assistant-reply.dto';
import { AI_REPLY_PROVIDER, AiReplyProvider } from './providers/ai-reply-provider.interface';

/**
 * The only server-side call site for a live LLM in this codebase — see
 * atlas-nova-bible.md's "Future: live AI" section and
 * build-session-7.md Part 9 for the client-side architecture
 * (`AiProvider.generateReply`) this plugs into. Delegates to whichever
 * `AiReplyProvider` `AssistantModule`'s factory selected (Build Session
 * 10 Part 14 added Openai/Gemini alongside the original Anthropic
 * adapter) — this class itself never talks to an LLM SDK directly, so
 * adding a provider never means touching this class or the controller.
 *
 * Build Session 10 Part 15 added real memory: `Preference.aiMemoryEnabled`
 * existed since the original schema but nothing ever read it. When it's
 * true, `reply()` reads the user's `CompanionMemory` notes into the
 * system prompt, and — best-effort, never blocking or failing the
 * reply itself — records this turn's input as a new note afterward.
 */
@Injectable()
export class AssistantService {
  constructor(
    @Inject(AI_REPLY_PROVIDER) private readonly provider: AiReplyProvider,
    private readonly prisma: PrismaService,
    private readonly memory: CompanionMemoryService,
  ) {}

  get isConfigured(): boolean {
    return this.provider.isConfigured;
  }

  async reply(dto: AssistantReplyDto, userId: string): Promise<string> {
    const memoryEnabled = await this.isMemoryEnabled(userId);
    const notes = memoryEnabled ? await this.memory.getNotes(userId) : [];

    const reply = await this.provider.generateReply(dto, notes);

    if (memoryEnabled) {
      // Best-effort — a memory write failing must never take down a
      // reply the user already received.
      await this.memory.remember(userId, dto.input).catch(() => undefined);
    }

    return reply;
  }

  getMemory(userId: string): Promise<string[]> {
    return this.memory.getNotes(userId);
  }

  clearMemory(userId: string): Promise<void> {
    return this.memory.clear(userId);
  }

  private async isMemoryEnabled(userId: string): Promise<boolean> {
    const preference = await this.prisma.preference.findUnique({ where: { userId } });
    // No Preference row yet mirrors the schema's own default (true)
    // rather than treating "not found" as "disabled."
    return preference?.aiMemoryEnabled ?? true;
  }
}
