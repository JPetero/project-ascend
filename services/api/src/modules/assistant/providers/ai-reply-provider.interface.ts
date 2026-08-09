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
  // memoryNotes (Build Session 10 Part 15) is optional so every existing
  // call site/test that omits it keeps working unchanged.
  generateReply(dto: AssistantReplyDto, memoryNotes?: string[]): Promise<string>;
}

export const AI_REPLY_PROVIDER = Symbol('AI_REPLY_PROVIDER');
