import { Inject, Injectable } from '@nestjs/common';
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
 */
@Injectable()
export class AssistantService {
  constructor(@Inject(AI_REPLY_PROVIDER) private readonly provider: AiReplyProvider) {}

  get isConfigured(): boolean {
    return this.provider.isConfigured;
  }

  reply(dto: AssistantReplyDto): Promise<string> {
    return this.provider.generateReply(dto);
  }
}
