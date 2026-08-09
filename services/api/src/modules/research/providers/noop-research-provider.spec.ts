import { ServiceUnavailableException } from '@nestjs/common';
import { NoopResearchProvider } from './noop-research-provider';

describe('NoopResearchProvider', () => {
  it('honestly rejects instead of fabricating a citation-backed answer', async () => {
    const provider = new NoopResearchProvider();

    expect(provider.isConfigured).toBe(false);
    await expect(provider.search()).rejects.toBeInstanceOf(ServiceUnavailableException);
  });
});
