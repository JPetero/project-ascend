import { ForbiddenException, Inject, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AiEntitlementService } from '../../common/entitlements/ai-entitlement.service';
import { AiFeature } from '../../common/entitlements/ai-entitlement.types';
import { AssistantSafetyService } from './assistant-safety.service';
import { AssistantSafetyDecisionType } from './assistant-safety.types';
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
 *
 * Build Session 11 Parts 1-2 closed the two biggest gaps found in this
 * pipeline: nothing server-side ever checked Premium entitlement before
 * calling a paid provider, and nothing server-side ever classified input
 * for safety — both were entirely a Flutter-client concern
 * (`AiProvider.reply()`), which a direct HTTP call bypassed completely.
 * `reply()` now runs every turn through `AssistantSafetyService` first:
 * safety-critical content never reaches a provider and is answered
 * deterministically regardless of subscription tier (essential safety
 * can never be paywalled or rate-limited away). Only after that gate
 * passes does `AiEntitlementService` decide whether this user's tier may
 * actually spend a live-provider call.
 */
@Injectable()
export class AssistantService {
  constructor(
    @Inject(AI_REPLY_PROVIDER) private readonly provider: AiReplyProvider,
    private readonly prisma: PrismaService,
    private readonly memory: CompanionMemoryService,
    private readonly safety: AssistantSafetyService,
    private readonly entitlement: AiEntitlementService,
  ) {}

  get isConfigured(): boolean {
    return this.provider.isConfigured;
  }

  async reply(dto: AssistantReplyDto, userId: string): Promise<string> {
    const safetyDecision = this.safety.classify(dto.input, dto.history);

    // LOCAL_SAFE_RESPONSE / ESCALATE / REFUSE all mean "never reaches a
    // provider" — available to every tier, never blocked, never costs
    // provider budget.
    if (safetyDecision.localResponse) {
      return safetyDecision.localResponse;
    }

    const access = await this.entitlement.checkAccess(userId, AiFeature.ADVANCED_CONVERSATION);
    if (!access.allowed) {
      // Mirrors ResearchController's existing pattern: the mobile
      // client's LiveAiProvider already falls back to the free local
      // deterministic companion on any error, so a Free account gets a
      // real reply, just not this one — and no provider is ever called.
      throw new ForbiddenException(access.reason ?? 'This requires Ascend Premium.');
    }

    const memoryEnabled = await this.isMemoryEnabled(userId);
    const notes = memoryEnabled ? await this.memory.getNotes(userId) : [];

    const safetyContext =
      safetyDecision.decision === AssistantSafetyDecisionType.ALLOW_WITH_SAFETY_CONTEXT
        ? safetyDecision.safetyContext
        : undefined;
    const rawReply = await this.provider.generateReply(dto, notes, safetyContext);
    const reply = this.safety.normalizeOutput(rawReply);

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
