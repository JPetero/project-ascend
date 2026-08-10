import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AiConfig } from '../../config/configuration';
import { AiProviderCircuitBreaker } from './ai-provider-circuit-breaker.service';
import { AiProviderAttempt } from './ai-resilience.types';
import { AssistantReplyDto } from './dto/assistant-reply.dto';
import { AiReplyProvider } from './providers/ai-reply-provider.interface';
import { AnthropicReplyProvider } from './providers/anthropic-reply-provider';
import { GeminiReplyProvider } from './providers/gemini-reply-provider';
import { OpenAiReplyProvider } from './providers/openai-reply-provider';

type ProviderKey = 'anthropic' | 'openai' | 'gemini';
const FALLBACK_ORDER: ProviderKey[] = ['anthropic', 'openai', 'gemini'];

/**
 * Resilient routing across every configured `AiReplyProvider` (Build
 * Session 12 Part 6). Before this, `AssistantModule`'s factory bound
 * `AI_REPLY_PROVIDER` to exactly one adapter (whichever `AI_PROVIDER` env
 * selected) — if that one provider errored or timed out, the whole
 * request failed even when a perfectly good alternate key was
 * configured. This class implements `AiReplyProvider` itself (same
 * `isConfigured`/`generateReply` shape), so it's a drop-in replacement
 * for the single-provider binding — `AssistantService` and the
 * controller never change.
 *
 * Order: the configured preferred provider first, then the remaining
 * two in a fixed order — skipping any provider that's `!isConfigured`
 * (no API key) or whose circuit is open
 * (`AiProviderCircuitBreaker.isHealthy` false), then calling the first
 * eligible one through the breaker's timeout. If it fails, the *next*
 * provider is tried — never the same message sent to two providers at
 * once, only ever sequential fallback. If every provider is unconfigured/
 * unhealthy/failing, this throws the same honest
 * `ServiceUnavailableException` a single provider always has — there is
 * no "local deterministic reply" invented here: the mobile client's
 * `LiveAiProvider` already catches exactly this and falls back to its
 * own free `LocalDeterministicAiProvider` (see that class's doc
 * comment), so duplicating that dialogue logic server-side would just be
 * redundant, not additionally safe.
 *
 * `lastAttempts` is a side-channel (same pattern as
 * `LiveAiProvider.pendingMemoryCandidate` on the mobile side) recording
 * every provider tried during the most recent `generateReply` call —
 * `AssistantService` reads it right after to log each attempt via
 * `AiUsagePolicy.record`, without widening the shared `AiReplyProvider`
 * interface every adapter/test implements.
 */
@Injectable()
export class AiReplyProviderRouter implements AiReplyProvider {
  private readonly preferred: ProviderKey;
  lastAttempts: AiProviderAttempt[] = [];

  constructor(
    private readonly configService: ConfigService,
    private readonly circuitBreaker: AiProviderCircuitBreaker,
    private readonly anthropic: AnthropicReplyProvider,
    private readonly openai: OpenAiReplyProvider,
    private readonly gemini: GeminiReplyProvider,
  ) {
    this.preferred = this.configService.get<AiConfig>('ai')!.provider;
  }

  get isConfigured(): boolean {
    return this.orderedProviders().some(([, provider]) => provider.isConfigured);
  }

  async generateReply(
    dto: AssistantReplyDto,
    memoryNotes?: string[],
    safetyContext?: string,
  ): Promise<string> {
    return this.executeWithFallback((provider) =>
      provider.generateReply(dto, memoryNotes, safetyContext),
    );
  }

  async generateResearchSynthesis(prompt: string): Promise<string> {
    return this.executeWithFallback((provider) => provider.generateResearchSynthesis(prompt));
  }

  /**
   * Shared sequential-fallback loop behind both `generateReply` and
   * `generateResearchSynthesis` (S13 Part 10-12) — the only difference
   * between the two is which method on each provider gets called, so the
   * ordering/circuit-breaker/`lastAttempts`-recording logic lives here
   * once instead of twice.
   */
  private async executeWithFallback<T>(
    callProvider: (provider: AiReplyProvider) => Promise<T>,
  ): Promise<T> {
    this.lastAttempts = [];
    let lastError: unknown;

    for (const [key, provider] of this.orderedProviders()) {
      if (!provider.isConfigured || !this.circuitBreaker.isHealthy(key)) continue;

      const startedAt = Date.now();
      try {
        const { result, latencyMs } = await this.circuitBreaker.execute(key, () =>
          callProvider(provider),
        );
        this.lastAttempts.push({
          provider: key,
          model: this.modelFor(key),
          success: true,
          latencyMs,
        });
        return result;
      } catch (error) {
        this.lastAttempts.push({
          provider: key,
          model: this.modelFor(key),
          success: false,
          latencyMs: Date.now() - startedAt,
        });
        lastError = error;
      }
    }

    if (lastError) throw lastError;
    throw new ServiceUnavailableException(
      'Live AI is not configured. Set an AI provider API key to enable it.',
    );
  }

  private orderedProviders(): [ProviderKey, AiReplyProvider][] {
    const order = [this.preferred, ...FALLBACK_ORDER.filter((key) => key !== this.preferred)];
    return order.map((key) => [key, this.providerFor(key)]);
  }

  private providerFor(key: ProviderKey): AiReplyProvider {
    switch (key) {
      case 'anthropic':
        return this.anthropic;
      case 'openai':
        return this.openai;
      case 'gemini':
        return this.gemini;
    }
  }

  private modelFor(key: ProviderKey): string {
    const ai = this.configService.get<AiConfig>('ai')!;
    switch (key) {
      case 'anthropic':
        return ai.anthropicModel;
      case 'openai':
        return ai.openaiModel;
      case 'gemini':
        return ai.geminiModel;
    }
  }
}
