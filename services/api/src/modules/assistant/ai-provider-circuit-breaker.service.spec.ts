import { AiProviderCircuitBreaker } from './ai-provider-circuit-breaker.service';

describe('AiProviderCircuitBreaker', () => {
  it('is healthy for a provider with no recorded history', () => {
    const breaker = new AiProviderCircuitBreaker();
    expect(breaker.isHealthy('anthropic')).toBe(true);
  });

  it('stays healthy after fewer than the failure threshold', async () => {
    const breaker = new AiProviderCircuitBreaker();
    await expect(
      breaker.execute('anthropic', () => Promise.reject(new Error('boom'))),
    ).rejects.toThrow('boom');
    await expect(
      breaker.execute('anthropic', () => Promise.reject(new Error('boom'))),
    ).rejects.toThrow('boom');

    expect(breaker.isHealthy('anthropic')).toBe(true);
  });

  it('opens the circuit after 3 consecutive failures', async () => {
    const breaker = new AiProviderCircuitBreaker();
    for (let i = 0; i < 3; i++) {
      await expect(
        breaker.execute('anthropic', () => Promise.reject(new Error('boom'))),
      ).rejects.toThrow('boom');
    }

    expect(breaker.isHealthy('anthropic')).toBe(false);
    expect(breaker.getHealth('anthropic').consecutiveFailures).toBe(3);
    expect(breaker.getHealth('anthropic').openUntil).not.toBeNull();
  });

  it('a success resets the failure count and closes the circuit', async () => {
    const breaker = new AiProviderCircuitBreaker();
    await expect(
      breaker.execute('anthropic', () => Promise.reject(new Error('boom'))),
    ).rejects.toThrow('boom');
    await expect(
      breaker.execute('anthropic', () => Promise.reject(new Error('boom'))),
    ).rejects.toThrow('boom');

    await breaker.execute('anthropic', () => Promise.resolve('ok'));

    expect(breaker.getHealth('anthropic').consecutiveFailures).toBe(0);
    expect(breaker.getHealth('anthropic').openUntil).toBeNull();
    expect(breaker.isHealthy('anthropic')).toBe(true);
  });

  it('failures for one provider key never affect another', async () => {
    const breaker = new AiProviderCircuitBreaker();
    for (let i = 0; i < 3; i++) {
      await expect(
        breaker.execute('anthropic', () => Promise.reject(new Error('boom'))),
      ).rejects.toThrow('boom');
    }

    expect(breaker.isHealthy('anthropic')).toBe(false);
    expect(breaker.isHealthy('openai')).toBe(true);
  });

  it('returns the resolved value and a non-negative latency on success', async () => {
    const breaker = new AiProviderCircuitBreaker();
    const { result, latencyMs } = await breaker.execute('anthropic', () =>
      Promise.resolve('hello'),
    );

    expect(result).toBe('hello');
    expect(latencyMs).toBeGreaterThanOrEqual(0);
  });

  it('times out a call that never settles rather than hanging forever', async () => {
    jest.useFakeTimers();
    const breaker = new AiProviderCircuitBreaker();
    const hanging = new Promise<string>(() => undefined);

    const promise = breaker.execute('anthropic', () => hanging);
    const assertion = expect(promise).rejects.toThrow('timed out');
    await jest.advanceTimersByTimeAsync(20_000);
    await assertion;

    expect(breaker.getHealth('anthropic').consecutiveFailures).toBe(1);
    jest.useRealTimers();
  });
});
