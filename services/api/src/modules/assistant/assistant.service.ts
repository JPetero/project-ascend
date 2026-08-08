import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Anthropic from '@anthropic-ai/sdk';
import { AiConfig } from '../../config/configuration';
import { AssistantReplyDto } from './dto/assistant-reply.dto';
import { buildMessages, buildSystemPrompt } from './assistant-prompt';

const MAX_REPLY_TOKENS = 400;

/**
 * The only server-side call site for a live LLM in this codebase — see
 * atlas-nova-bible.md's "Future: live AI" section and
 * build-session-7.md Part 9 for the client-side architecture
 * (`AiProvider.generateReply`) this plugs into. No `ANTHROPIC_API_KEY`
 * exists in this environment, so this honestly rejects with "not
 * configured" (503) rather than pretending to generate a reply — the
 * mobile app's `LiveAiProvider` falls back to the free, deterministic
 * local companion whenever this throws. The request-shaping logic
 * (`buildSystemPrompt`/`buildMessages`) is covered by unit tests, but a
 * live network call to Anthropic is not exercised in this environment —
 * see build-session-9.md's disclosed limitation.
 */
@Injectable()
export class AssistantService {
  private readonly apiKey: string | undefined;
  private readonly model: string;
  private client: Anthropic | undefined;

  constructor(private readonly configService: ConfigService) {
    const aiConfig = this.configService.get<AiConfig>('ai')!;
    this.apiKey = aiConfig.anthropicApiKey;
    this.model = aiConfig.anthropicModel;
  }

  get isConfigured(): boolean {
    return Boolean(this.apiKey);
  }

  async reply(dto: AssistantReplyDto): Promise<string> {
    if (!this.apiKey) {
      throw new ServiceUnavailableException(
        'Live AI is not configured. Set ANTHROPIC_API_KEY to enable it.',
      );
    }
    this.client ??= new Anthropic({ apiKey: this.apiKey });

    const message = await this.client.messages.create({
      model: this.model,
      max_tokens: MAX_REPLY_TOKENS,
      system: buildSystemPrompt(dto.companion, dto.style),
      messages: buildMessages(dto.history, dto.input),
    });

    const text = message.content
      .filter((block) => block.type === 'text')
      .map((block) => (block as { text: string }).text)
      .join('\n')
      .trim();

    if (!text) {
      throw new ServiceUnavailableException('Live AI returned an empty reply.');
    }
    return text;
  }
}
