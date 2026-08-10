import { ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CoachingStyleDto, CompanionDto } from '../assistant.types';
import { GeminiReplyProvider } from './gemini-reply-provider';

describe('GeminiReplyProvider', () => {
  it('honestly rejects instead of pretending to reply when no API key is configured', async () => {
    const configService = {
      get: () => ({ geminiApiKey: undefined, geminiModel: 'gemini-2.0-flash-001' }),
    } as unknown as ConfigService;
    const provider = new GeminiReplyProvider(configService);

    expect(provider.isConfigured).toBe(false);
    await expect(
      provider.generateReply({
        input: 'plan my workout',
        companion: CompanionDto.ATLAS,
        style: CoachingStyleDto.BALANCED,
      }),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
  });

  it('honestly rejects generateResearchSynthesis when no API key is configured', async () => {
    const configService = {
      get: () => ({ geminiApiKey: undefined, geminiModel: 'gemini-2.0-flash-001' }),
    } as unknown as ConfigService;
    const provider = new GeminiReplyProvider(configService);

    await expect(
      provider.generateResearchSynthesis('summarize these sources'),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
  });

  it('reports configured when an API key is present, without making a network call', () => {
    const configService = {
      get: () => ({ geminiApiKey: 'test-key', geminiModel: 'gemini-2.0-flash-001' }),
    } as unknown as ConfigService;
    const provider = new GeminiReplyProvider(configService);

    expect(provider.isConfigured).toBe(true);
  });
});
