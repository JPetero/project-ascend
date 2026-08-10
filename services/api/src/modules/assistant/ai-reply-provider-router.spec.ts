import { ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AiProviderCircuitBreaker } from './ai-provider-circuit-breaker.service';
import { AiReplyProviderRouter } from './ai-reply-provider-router';
import { AssistantReplyDto, CoachingStyleDto, CompanionDto } from './dto/assistant-reply.dto';
import { AnthropicReplyProvider } from './providers/anthropic-reply-provider';
import { GeminiReplyProvider } from './providers/gemini-reply-provider';
import { OpenAiReplyProvider } from './providers/openai-reply-provider';

function configServiceWith(
  preferred: 'anthropic' | 'openai' | 'gemini' = 'anthropic',
): ConfigService {
  return {
    get: () => ({
      provider: preferred,
      anthropicModel: 'claude-x',
      openaiModel: 'gpt-x',
      geminiModel: 'gemini-x',
    }),
  } as unknown as ConfigService;
}

function fakeProvider(
  overrides: {
    isConfigured?: boolean;
    generateReply?: jest.Mock;
    generateResearchSynthesis?: jest.Mock;
  } = {},
) {
  return {
    isConfigured: overrides.isConfigured ?? true,
    generateReply: overrides.generateReply ?? jest.fn().mockResolvedValue('a reply'),
    generateResearchSynthesis:
      overrides.generateResearchSynthesis ?? jest.fn().mockResolvedValue('a synthesis'),
  };
}

const dto: AssistantReplyDto = {
  input: 'hello',
  companion: CompanionDto.ATLAS,
  style: CoachingStyleDto.BALANCED,
};

describe('AiReplyProviderRouter', () => {
  it('calls only the preferred provider when it succeeds', async () => {
    const anthropic = fakeProvider();
    const openai = fakeProvider();
    const gemini = fakeProvider();
    const router = new AiReplyProviderRouter(
      configServiceWith('anthropic'),
      new AiProviderCircuitBreaker(),
      anthropic as unknown as AnthropicReplyProvider,
      openai as unknown as OpenAiReplyProvider,
      gemini as unknown as GeminiReplyProvider,
    );

    const reply = await router.generateReply(dto);

    expect(reply).toBe('a reply');
    expect(anthropic.generateReply).toHaveBeenCalledTimes(1);
    expect(openai.generateReply).not.toHaveBeenCalled();
    expect(gemini.generateReply).not.toHaveBeenCalled();
    expect(router.lastAttempts).toEqual([
      { provider: 'anthropic', model: 'claude-x', success: true, latencyMs: expect.any(Number) },
    ]);
  });

  it('skips an unconfigured preferred provider and falls back to the next configured one', async () => {
    const anthropic = fakeProvider({ isConfigured: false });
    const openai = fakeProvider();
    const gemini = fakeProvider();
    const router = new AiReplyProviderRouter(
      configServiceWith('anthropic'),
      new AiProviderCircuitBreaker(),
      anthropic as unknown as AnthropicReplyProvider,
      openai as unknown as OpenAiReplyProvider,
      gemini as unknown as GeminiReplyProvider,
    );

    await router.generateReply(dto);

    expect(anthropic.generateReply).not.toHaveBeenCalled();
    expect(openai.generateReply).toHaveBeenCalledTimes(1);
    expect(router.lastAttempts).toEqual([
      { provider: 'openai', model: 'gpt-x', success: true, latencyMs: expect.any(Number) },
    ]);
  });

  it('falls back sequentially on failure — never calls two providers concurrently for the same message', async () => {
    const callOrder: string[] = [];
    const anthropic = fakeProvider({
      generateReply: jest.fn().mockImplementation(async () => {
        callOrder.push('anthropic-start');
        throw new Error('anthropic down');
      }),
    });
    const openai = fakeProvider({
      generateReply: jest.fn().mockImplementation(async () => {
        callOrder.push('openai-start');
        return 'openai reply';
      }),
    });
    const gemini = fakeProvider();
    const router = new AiReplyProviderRouter(
      configServiceWith('anthropic'),
      new AiProviderCircuitBreaker(),
      anthropic as unknown as AnthropicReplyProvider,
      openai as unknown as OpenAiReplyProvider,
      gemini as unknown as GeminiReplyProvider,
    );

    const reply = await router.generateReply(dto);

    expect(reply).toBe('openai reply');
    expect(callOrder).toEqual(['anthropic-start', 'openai-start']);
    expect(gemini.generateReply).not.toHaveBeenCalled();
    expect(router.lastAttempts).toEqual([
      { provider: 'anthropic', model: 'claude-x', success: false, latencyMs: expect.any(Number) },
      { provider: 'openai', model: 'gpt-x', success: true, latencyMs: expect.any(Number) },
    ]);
  });

  it('throws the last provider error when every configured provider fails', async () => {
    const anthropic = fakeProvider({
      generateReply: jest.fn().mockRejectedValue(new Error('anthropic down')),
    });
    const openai = fakeProvider({
      generateReply: jest.fn().mockRejectedValue(new Error('openai down')),
    });
    const gemini = fakeProvider({
      generateReply: jest.fn().mockRejectedValue(new Error('gemini down')),
    });
    const router = new AiReplyProviderRouter(
      configServiceWith('anthropic'),
      new AiProviderCircuitBreaker(),
      anthropic as unknown as AnthropicReplyProvider,
      openai as unknown as OpenAiReplyProvider,
      gemini as unknown as GeminiReplyProvider,
    );

    await expect(router.generateReply(dto)).rejects.toThrow('gemini down');
    expect(router.lastAttempts).toHaveLength(3);
  });

  it('honestly rejects when nothing is configured, without inventing a local reply', async () => {
    const anthropic = fakeProvider({ isConfigured: false });
    const openai = fakeProvider({ isConfigured: false });
    const gemini = fakeProvider({ isConfigured: false });
    const router = new AiReplyProviderRouter(
      configServiceWith('anthropic'),
      new AiProviderCircuitBreaker(),
      anthropic as unknown as AnthropicReplyProvider,
      openai as unknown as OpenAiReplyProvider,
      gemini as unknown as GeminiReplyProvider,
    );

    await expect(router.generateReply(dto)).rejects.toBeInstanceOf(ServiceUnavailableException);
    expect(router.lastAttempts).toEqual([]);
  });

  it('isConfigured is true if any provider has a key, even when the preferred one does not', () => {
    const anthropic = fakeProvider({ isConfigured: false });
    const openai = fakeProvider({ isConfigured: true });
    const gemini = fakeProvider({ isConfigured: false });
    const router = new AiReplyProviderRouter(
      configServiceWith('anthropic'),
      new AiProviderCircuitBreaker(),
      anthropic as unknown as AnthropicReplyProvider,
      openai as unknown as OpenAiReplyProvider,
      gemini as unknown as GeminiReplyProvider,
    );

    expect(router.isConfigured).toBe(true);
  });

  it('skips a provider once its circuit opens from repeated failures, going straight to the next', async () => {
    const anthropic = fakeProvider({
      generateReply: jest.fn().mockRejectedValue(new Error('down')),
    });
    const openai = fakeProvider();
    const gemini = fakeProvider();
    const breaker = new AiProviderCircuitBreaker();
    const router = new AiReplyProviderRouter(
      configServiceWith('anthropic'),
      breaker,
      anthropic as unknown as AnthropicReplyProvider,
      openai as unknown as OpenAiReplyProvider,
      gemini as unknown as GeminiReplyProvider,
    );

    // 3 consecutive failures open anthropic's circuit.
    await router.generateReply(dto);
    await router.generateReply(dto);
    await router.generateReply(dto);
    expect(anthropic.generateReply).toHaveBeenCalledTimes(3);

    await router.generateReply(dto);

    // The circuit is open now — anthropic is never attempted again.
    expect(anthropic.generateReply).toHaveBeenCalledTimes(3);
    expect(openai.generateReply).toHaveBeenCalledTimes(4);
  });

  describe('generateResearchSynthesis', () => {
    it('calls only the preferred provider when it succeeds', async () => {
      const anthropic = fakeProvider({
        generateResearchSynthesis: jest.fn().mockResolvedValue('grounded answer'),
      });
      const openai = fakeProvider();
      const gemini = fakeProvider();
      const router = new AiReplyProviderRouter(
        configServiceWith('anthropic'),
        new AiProviderCircuitBreaker(),
        anthropic as unknown as AnthropicReplyProvider,
        openai as unknown as OpenAiReplyProvider,
        gemini as unknown as GeminiReplyProvider,
      );

      const result = await router.generateResearchSynthesis('summarize these sources');

      expect(result).toBe('grounded answer');
      expect(anthropic.generateResearchSynthesis).toHaveBeenCalledWith('summarize these sources');
      expect(openai.generateResearchSynthesis).not.toHaveBeenCalled();
    });

    it('falls back sequentially on failure, same as generateReply', async () => {
      const anthropic = fakeProvider({
        generateResearchSynthesis: jest.fn().mockRejectedValue(new Error('anthropic down')),
      });
      const openai = fakeProvider({
        generateResearchSynthesis: jest.fn().mockResolvedValue('openai synthesis'),
      });
      const gemini = fakeProvider();
      const router = new AiReplyProviderRouter(
        configServiceWith('anthropic'),
        new AiProviderCircuitBreaker(),
        anthropic as unknown as AnthropicReplyProvider,
        openai as unknown as OpenAiReplyProvider,
        gemini as unknown as GeminiReplyProvider,
      );

      const result = await router.generateResearchSynthesis('summarize these sources');

      expect(result).toBe('openai synthesis');
      expect(gemini.generateResearchSynthesis).not.toHaveBeenCalled();
    });

    it('honestly rejects when nothing is configured', async () => {
      const anthropic = fakeProvider({ isConfigured: false });
      const openai = fakeProvider({ isConfigured: false });
      const gemini = fakeProvider({ isConfigured: false });
      const router = new AiReplyProviderRouter(
        configServiceWith('anthropic'),
        new AiProviderCircuitBreaker(),
        anthropic as unknown as AnthropicReplyProvider,
        openai as unknown as OpenAiReplyProvider,
        gemini as unknown as GeminiReplyProvider,
      );

      await expect(
        router.generateResearchSynthesis('summarize these sources'),
      ).rejects.toBeInstanceOf(ServiceUnavailableException);
    });
  });
});
