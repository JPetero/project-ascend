import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';
import { AiConfig } from '../../../config/configuration';
import { buildMessages, buildSystemPrompt } from '../assistant-prompt';
import { AssistantReplyDto } from '../dto/assistant-reply.dto';
import { AiReplyProvider } from './ai-reply-provider.interface';

const MAX_REPLY_TOKENS = 400;
const MAX_SYNTHESIS_TOKENS = 600;

/**
 * Build Session 10 Part 14 — selectable via `AI_PROVIDER=openai`. No
 * `OPENAI_API_KEY` exists in this environment, so this honestly rejects
 * with "not configured" (503) rather than pretending to generate a
 * reply, same as every other provider here. Not exercised against a
 * live network call in this environment.
 */
@Injectable()
export class OpenAiReplyProvider implements AiReplyProvider {
  private readonly apiKey: string | undefined;
  private readonly model: string;
  private client: OpenAI | undefined;

  constructor(private readonly configService: ConfigService) {
    const aiConfig = this.configService.get<AiConfig>('ai')!;
    this.apiKey = aiConfig.openaiApiKey;
    this.model = aiConfig.openaiModel;
  }

  get isConfigured(): boolean {
    return Boolean(this.apiKey);
  }

  async generateReply(
    dto: AssistantReplyDto,
    memoryNotes?: string[],
    safetyContext?: string,
  ): Promise<string> {
    if (!this.apiKey) {
      throw new ServiceUnavailableException(
        'Live AI is not configured. Set OPENAI_API_KEY to enable it.',
      );
    }
    this.client ??= new OpenAI({ apiKey: this.apiKey });

    const completion = await this.client.chat.completions.create({
      model: this.model,
      max_completion_tokens: MAX_REPLY_TOKENS,
      messages: [
        {
          role: 'system',
          content: buildSystemPrompt(dto.companion, dto.style, memoryNotes, safetyContext),
        },
        ...buildMessages(dto.history, dto.input),
      ],
    });

    const text = completion.choices[0]?.message.content?.trim();
    if (!text) {
      throw new ServiceUnavailableException('Live AI returned an empty reply.');
    }
    return text;
  }

  async generateResearchSynthesis(prompt: string): Promise<string> {
    if (!this.apiKey) {
      throw new ServiceUnavailableException(
        'Live AI is not configured. Set OPENAI_API_KEY to enable it.',
      );
    }
    this.client ??= new OpenAI({ apiKey: this.apiKey });

    const completion = await this.client.chat.completions.create({
      model: this.model,
      max_completion_tokens: MAX_SYNTHESIS_TOKENS,
      messages: [{ role: 'user', content: prompt }],
    });

    const text = completion.choices[0]?.message.content?.trim();
    if (!text) {
      throw new ServiceUnavailableException('Live AI returned an empty reply.');
    }
    return text;
  }
}
