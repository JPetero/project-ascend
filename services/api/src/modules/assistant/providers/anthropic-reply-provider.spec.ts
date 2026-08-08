import { ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CoachingStyleDto, CompanionDto } from '../assistant.types';
import { AnthropicReplyProvider } from './anthropic-reply-provider';

describe('AnthropicReplyProvider', () => {
  it('honestly rejects instead of pretending to reply when no API key is configured', async () => {
    const configService = {
      get: () => ({ anthropicApiKey: undefined, anthropicModel: 'claude-haiku-4-5-20251001' }),
    } as unknown as ConfigService;
    const provider = new AnthropicReplyProvider(configService);

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
      get: () => ({ anthropicApiKey: 'sk-test-key', anthropicModel: 'claude-haiku-4-5-20251001' }),
    } as unknown as ConfigService;
    const provider = new AnthropicReplyProvider(configService);

    expect(provider.isConfigured).toBe(true);
  });
});
