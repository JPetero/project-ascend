import { AssistantService } from './assistant.service';
import { AiReplyProvider } from './providers/ai-reply-provider.interface';
import { CoachingStyleDto, CompanionDto } from './assistant.types';

describe('AssistantService', () => {
  it('delegates isConfigured to whichever AiReplyProvider was injected', () => {
    const provider: AiReplyProvider = { isConfigured: true, generateReply: jest.fn() };
    const service = new AssistantService(provider);

    expect(service.isConfigured).toBe(true);
  });

  it('reports not configured when the injected provider is not', () => {
    const provider: AiReplyProvider = { isConfigured: false, generateReply: jest.fn() };
    const service = new AssistantService(provider);

    expect(service.isConfigured).toBe(false);
  });

  it('reply() passes the dto straight through to the provider and returns its result', async () => {
    const generateReply = jest.fn().mockResolvedValue('Nice work today!');
    const provider: AiReplyProvider = { isConfigured: true, generateReply };
    const service = new AssistantService(provider);
    const dto = {
      input: 'plan my workout',
      companion: CompanionDto.ATLAS,
      style: CoachingStyleDto.BALANCED,
    };

    const reply = await service.reply(dto);

    expect(generateReply).toHaveBeenCalledWith(dto);
    expect(reply).toBe('Nice work today!');
  });
});
