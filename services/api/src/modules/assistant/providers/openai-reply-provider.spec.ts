import { ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CoachingStyleDto, CompanionDto } from '../assistant.types';
import { OpenAiReplyProvider } from './openai-reply-provider';

describe('OpenAiReplyProvider', () => {
  it('honestly rejects instead of pretending to reply when no API key is configured', async () => {
    const configService = {
      get: () => ({ openaiApiKey: undefined, openaiModel: 'gpt-4o-mini' }),
    } as unknown as ConfigService;
    const provider = new OpenAiReplyProvider(configService);

    expect(provider.isConfigured).toBe(false);
    await expect(
      provider.generateReply({
        input: 'plan my workout',
        companion: CompanionDto.ATLAS,
        style: CoachingStyleDto.BALANCED,
      }),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
  });

  it('reports configured when an API key is present, without making a network call', () => {
    const configService = {
      get: () => ({ openaiApiKey: 'sk-test-key', openaiModel: 'gpt-4o-mini' }),
    } as unknown as ConfigService;
    const provider = new OpenAiReplyProvider(configService);

    expect(provider.isConfigured).toBe(true);
  });
});
