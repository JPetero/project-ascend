import { Injectable } from '@nestjs/common';
import { ProviderHealth } from './ai-resilience.types';

const FAILURE_THRESHOLD = 3;
const COOLDOWN_MS = 60_000;
const TIMEOUT_MS = 20_000;

/**
 * Per-provider circuit breaker (Build Session 12 Part 6) — before this,
 * a slow or erroring provider was retried on literally every request
 * (nothing remembered a prior failure), so a degraded provider stayed in
 * the routing path indefinitely, adding latency (or a full timeout) to
 * every reply until someone changed `AI_PROVIDER` by hand. Now 3
 * consecutive failures opens the circuit for 60s — `AiReplyProviderRouter`
 * skips an open-circuit provider and tries the next one instead of ever
 * calling it. `TIMEOUT_MS` bounds a single call's latency so one hanging
 * provider can't stall a reply indefinitely.
 *
 * Deliberately does not retry the same provider within `execute` — one
 * attempt, timeout-bounded, then success/failure is recorded and control
 * returns to the caller. This keeps "never resend the same message to
 * multiple providers concurrently" trivially true: the router only ever
 * calls the next provider sequentially, after this one has already
 * finished or timed out, never in parallel.
 *
 * In-memory only (per process) — acceptable for this single-instance
 * deployment; a future multi-instance deployment would need this shared
 * (e.g. Redis) the same way a production circuit breaker normally is.
 */
@Injectable()
export class AiProviderCircuitBreaker {
  private readonly health = new Map<string, ProviderHealth>();

  isHealthy(providerKey: string): boolean {
    const state = this.health.get(providerKey);
    if (!state?.openUntil) return true;
    return state.openUntil.getTime() <= Date.now();
  }

  getHealth(providerKey: string): ProviderHealth {
    return this.health.get(providerKey) ?? { consecutiveFailures: 0, openUntil: null };
  }

  async execute<T>(
    providerKey: string,
    fn: () => Promise<T>,
  ): Promise<{ result: T; latencyMs: number }> {
    const startedAt = Date.now();
    let timeoutHandle: ReturnType<typeof setTimeout> | undefined;
    const timeout = new Promise<never>((_, reject) => {
      timeoutHandle = setTimeout(
        () => reject(new Error(`${providerKey} timed out after ${TIMEOUT_MS}ms`)),
        TIMEOUT_MS,
      );
    });

    try {
      const result = await Promise.race([fn(), timeout]);
      this.recordSuccess(providerKey);
      return { result, latencyMs: Date.now() - startedAt };
    } catch (error) {
      this.recordFailure(providerKey);
      throw error;
    } finally {
      clearTimeout(timeoutHandle);
    }
  }

  private recordSuccess(providerKey: string): void {
    this.health.set(providerKey, { consecutiveFailures: 0, openUntil: null });
  }

  private recordFailure(providerKey: string): void {
    const previous = this.getHealth(providerKey);
    const consecutiveFailures = previous.consecutiveFailures + 1;
    const openUntil =
      consecutiveFailures >= FAILURE_THRESHOLD ? new Date(Date.now() + COOLDOWN_MS) : null;
    this.health.set(providerKey, { consecutiveFailures, openUntil });
  }
}
