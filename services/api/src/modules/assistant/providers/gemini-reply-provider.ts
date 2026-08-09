import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Content, GoogleGenerativeAI } from '@google/generative-ai';
import { AiConfig } from '../../../config/configuration';
import { buildSystemPrompt } from '../assistant-prompt';
import { AssistantReplyDto } from '../dto/assistant-reply.dto';
import { AiReplyProvider } from './ai-reply-provider.interface';

const MAX_REPLY_TOKENS = 400;

/**
 * Build Session 10 Part 14 — selectable via `AI_PROVIDER=gemini`. No
 * `GEMINI_API_KEY` exists in this environment, so this honestly rejects
 * with "not configured" (503) rather than pretending to generate a
 * reply, same as every other provider here. Not exercised against a
 * live network call in this environment.
 *
 * Gemini's chat API takes prior turns and the new input separately
 * (`startChat({history})` then `sendMessage(input)`), unlike Anthropic/
 * OpenAI's single flat messages array — so this maps `dto.history`
 * directly instead of reusing `buildMessages`.
 */
@Injectable()
export class GeminiReplyProvider implements AiReplyProvider {
  private readonly apiKey: string | undefined;
  private readonly model: string;
  private client: GoogleGenerativeAI | undefined;

  constructor(private readonly configService: ConfigService) {
    const aiConfig = this.configService.get<AiConfig>('ai')!;
    this.apiKey = aiConfig.geminiApiKey;
    this.model = aiConfig.geminiModel;
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
        'Live AI is not configured. Set GEMINI_API_KEY to enable it.',
      );
    }
    this.client ??= new GoogleGenerativeAI(this.apiKey);

    const model = this.client.getGenerativeModel({
      model: this.model,
      systemInstruction: buildSystemPrompt(dto.companion, dto.style, memoryNotes, safetyContext),
      generationConfig: { maxOutputTokens: MAX_REPLY_TOKENS },
    });

    const history: Content[] = (dto.history ?? []).map((message) => ({
      role: message.isFromUser ? 'user' : 'model',
      parts: [{ text: message.text }],
    }));

    const chat = model.startChat({ history });
    const result = await chat.sendMessage(dto.input);
    const text = result.response.text().trim();

    if (!text) {
      throw new ServiceUnavailableException('Live AI returned an empty reply.');
    }
    return text;
  }
}
