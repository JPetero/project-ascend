import { ForbiddenException, Inject, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AiEntitlementService } from '../../common/entitlements/ai-entitlement.service';
import { AiFeature } from '../../common/entitlements/ai-entitlement.types';
import { AiReplyProviderRouter } from './ai-reply-provider-router';
import { AiUsagePolicy, FAIR_USE_LIMIT_MESSAGE } from './ai-usage-policy.service';
import { AssistantSafetyService } from './assistant-safety.service';
import { AssistantSafetyDecisionType } from './assistant-safety.types';
import { CompanionMemoryNoteView, CompanionMemoryService } from './companion-memory.service';
import { AssistantReplyDto } from './dto/assistant-reply.dto';
import { MemoryExtractionService } from './memory-extraction.service';
import { MemoryCandidate, MemorySensitivity, memorySensitivityOf } from './memory-extraction.types';
import { AI_REPLY_PROVIDER, AiReplyProvider } from './providers/ai-reply-provider.interface';

export interface AssistantReplyResult {
  reply: string;
  /** Set only when extraction found a SENSITIVE-category fact (Build
   * Session 12 Part 4) — never auto-saved. The client shows a "remember
   * this?" prompt and, if the user agrees, calls `confirmMemory` with
   * this exact category/value. */
  pendingMemory?: MemoryCandidate;
}

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
 *
 * Build Session 11 Part 4 replaced the original "remember any message
 * over 12 characters, verbatim" memory heuristic with structured,
 * category-limited extraction (`MemoryExtractionService`) — see that
 * service's doc comment for the privacy boundary. Extraction only ever
 * runs on turns the safety gate already classified as safe to learn
 * from (never pain/medical/eating-disorder/self-harm/sexual/dependency/
 * etc. content), and only when the user has explicitly enabled memory
 * (`Preference.aiMemoryEnabled`, opt-in by default now).
 */
@Injectable()
export class AssistantService {
  constructor(
    @Inject(AI_REPLY_PROVIDER) private readonly provider: AiReplyProvider,
    private readonly prisma: PrismaService,
    private readonly memory: CompanionMemoryService,
    private readonly safety: AssistantSafetyService,
    private readonly entitlement: AiEntitlementService,
    private readonly extraction: MemoryExtractionService,
    private readonly usagePolicy: AiUsagePolicy,
  ) {}

  get isConfigured(): boolean {
    return this.provider.isConfigured;
  }

  async reply(dto: AssistantReplyDto, userId: string): Promise<AssistantReplyResult> {
    const safetyDecision = this.safety.classify(dto.input, dto.history);

    // LOCAL_SAFE_RESPONSE / ESCALATE / REFUSE all mean "never reaches a
    // provider" — available to every tier, never blocked, never costs
    // provider budget, and never offered to the memory extractor either.
    if (safetyDecision.localResponse) {
      return { reply: safetyDecision.localResponse };
    }

    const access = await this.entitlement.checkAccess(userId, AiFeature.ADVANCED_CONVERSATION);
    if (!access.allowed) {
      // Mirrors ResearchController's existing pattern: the mobile
      // client's LiveAiProvider already falls back to the free local
      // deterministic companion on any error, so a Free account gets a
      // real reply, just not this one — and no provider is ever called.
      throw new ForbiddenException(access.reason ?? 'This requires Ascend Premium.');
    }

    // Fair-use ceiling (Build Session 12 Part 6) — separate from the
    // tier check above, which only answers "is this feature in this
    // plan at all." Only ever engages for abnormal volume; see
    // AiUsagePolicy's doc comment for why this is never a user-facing
    // credit system.
    const usage = await this.usagePolicy.checkWithinLimit(userId, AiFeature.ADVANCED_CONVERSATION);
    if (!usage.allowed) {
      throw new ForbiddenException(FAIR_USE_LIMIT_MESSAGE);
    }

    const memoryEnabled = await this.isMemoryEnabled(userId);
    const notes = memoryEnabled ? await this.memory.getNotes(userId) : [];

    const safetyContext =
      safetyDecision.decision === AssistantSafetyDecisionType.ALLOW_WITH_SAFETY_CONTEXT
        ? safetyDecision.safetyContext
        : undefined;
    const rawReply = await this.provider.generateReply(
      dto,
      notes.map((note) => note.value),
      safetyContext,
    );
    const reply = this.safety.normalizeOutput(rawReply);

    // Build Session 12 Part 6 — every provider attempt this call made
    // (see AiReplyProviderRouter.lastAttempts's doc comment for why this
    // is a side-channel rather than a widened AiReplyProvider contract).
    // Only entitled, Premium accounts ever reach this line (the
    // ForbiddenException above already returned for anyone else), so the
    // tier is recorded as PREMIUM rather than re-querying it.
    if (this.provider instanceof AiReplyProviderRouter) {
      for (const attempt of this.provider.lastAttempts) {
        void this.usagePolicy.record({
          userId,
          provider: attempt.provider,
          model: attempt.model,
          feature: AiFeature.ADVANCED_CONVERSATION,
          tier: 'PREMIUM',
          success: attempt.success,
          latencyMs: attempt.latencyMs,
          inputChars: dto.input.length,
          outputChars: attempt.success ? reply.length : undefined,
        });
      }
    }

    let pendingMemory: MemoryCandidate | undefined;
    if (memoryEnabled) {
      const candidate = this.extraction.extractCandidate(dto.input, safetyDecision.category);
      if (candidate) {
        if (memorySensitivityOf(candidate.category) === MemorySensitivity.SENSITIVE) {
          // Never auto-saved — surfaced to the client for explicit
          // confirmation instead (see `confirmMemory`).
          pendingMemory = candidate;
        } else {
          // Best-effort — a memory write failing must never take down a
          // reply the user already received.
          await this.memory.remember(userId, candidate).catch(() => undefined);
        }
      }
    }

    return { reply, pendingMemory };
  }

  /**
   * Explicit user confirmation for a SENSITIVE candidate `reply` earlier
   * surfaced but did not save (Build Session 12 Part 4). Deliberately
   * does not re-derive sensitivity or re-run extraction — the client is
   * confirming a specific fact it was already shown, not submitting
   * arbitrary free text (`ConfirmMemoryDto` still bounds the category to
   * the same allowed enum and the value to the same length limit
   * extraction itself enforces).
   */
  confirmMemory(userId: string, candidate: MemoryCandidate): Promise<void> {
    return this.memory.remember(userId, candidate);
  }

  getMemory(userId: string): Promise<CompanionMemoryNoteView[]> {
    return this.memory.getNotes(userId);
  }

  deleteMemory(userId: string, noteId: string): Promise<void> {
    return this.memory.deleteNote(userId, noteId);
  }

  clearMemory(userId: string): Promise<void> {
    return this.memory.clear(userId);
  }

  private async isMemoryEnabled(userId: string): Promise<boolean> {
    const preference = await this.prisma.preference.findUnique({ where: { userId } });
    // No Preference row yet mirrors the schema's own default (false —
    // opt-in, Build Session 11 Part 4) rather than assuming enabled.
    return preference?.aiMemoryEnabled ?? false;
  }
}
