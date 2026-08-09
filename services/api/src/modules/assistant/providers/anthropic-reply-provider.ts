import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Anthropic from '@anthropic-ai/sdk';
import { AiConfig } from '../../../config/configuration';
import { buildMessages, buildSystemPrompt } from '../assistant-prompt';
import { AssistantReplyDto } from '../dto/assistant-reply.dto';
import { AiReplyProvider } from './ai-reply-provider.interface';

const MAX_REPLY_TOKENS = 400;

/**
 * The original (Build Session 9 Part 15/16) live-LLM adapter, and this
 * app's default `AI_PROVIDER`. No `ANTHROPIC_API_KEY` exists in this
 * environment, so this honestly rejects with "not configured" (503)
 * rather than pretending to generate a reply — the mobile app's
 * `LiveAiProvider` falls back to the free, deterministic local companion
 * whenever this throws. Not exercised against a live network call in
 * this environment — see build-session-9.md's disclosed limitation.
 */
@Injectable()
export class AnthropicReplyProvider implements AiReplyProvider {
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

  async generateReply(dto: AssistantReplyDto, memoryNotes?: string[]): Promise<string> {
    if (!this.apiKey) {
      throw new ServiceUnavailableException(
        'Live AI is not configured. Set ANTHROPIC_API_KEY to enable it.',
      );
    }
    this.client ??= new Anthropic({ apiKey: this.apiKey });

    const message = await this.client.messages.create({
      model: this.model,
      max_tokens: MAX_REPLY_TOKENS,
      system: buildSystemPrompt(dto.companion, dto.style, memoryNotes),
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
