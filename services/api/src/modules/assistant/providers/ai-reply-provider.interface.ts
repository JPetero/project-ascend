import { AssistantReplyDto } from '../dto/assistant-reply.dto';

/**
 * Swappable live-LLM adapter (Build Session 10 Part 14) — the interface
 * `AssistantService` delegates to, so adding a provider never means
 * touching the controller or the request-shaping logic
 * (`buildSystemPrompt`/`buildMessages`). Every implementation honestly
 * rejects instead of pretending to reply when its own API key is unset;
 * see AssistantModule's factory for how the active one is selected.
 */
export interface AiReplyProvider {
  readonly isConfigured: boolean;
  // memoryNotes (Build Session 10 Part 15) and safetyContext (Build
  // Session 11 Part 2) are both optional so every existing call site/test
  // that omits them keeps working unchanged.
  generateReply(
    dto: AssistantReplyDto,
    memoryNotes?: string[],
    safetyContext?: string,
  ): Promise<string>;
  // S13 Part 10-12 — a single-turn, persona-free completion used by
  // ResearchSynthesisService to generate a grounded, citation-tagged
  // answer from a flat prompt. Deliberately not `generateReply`: that
  // method's `AssistantReplyDto`/`buildSystemPrompt` shape injects Atlas/
  // Nova companion-persona framing, which would be actively wrong context
  // for research synthesis. Every implementation honestly rejects when
  // unconfigured, same as `generateReply`.
  generateResearchSynthesis(prompt: string): Promise<string>;
}

export const AI_REPLY_PROVIDER = Symbol('AI_REPLY_PROVIDER');
