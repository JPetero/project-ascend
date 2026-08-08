import { ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AssistantService } from './assistant.service';
import { CoachingStyleDto, CompanionDto } from './assistant.types';

describe('AssistantService', () => {
  it('honestly rejects instead of pretending to reply when no API key is configured', async () => {
    const configService = {
      get: () => ({ anthropicApiKey: undefined, anthropicModel: 'claude-haiku-4-5-20251001' }),
    } as unknown as ConfigService;
    const service = new AssistantService(configService);

    expect(service.isConfigured).toBe(false);
    await expect(
      service.reply({
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
    const service = new AssistantService(configService);

    expect(service.isConfigured).toBe(true);
  });
});
