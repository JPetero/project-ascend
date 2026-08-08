import { ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApplePurchaseVerifier } from './apple-purchase-verifier';

describe('ApplePurchaseVerifier', () => {
  it('honestly rejects instead of pretending to verify when no shared secret is configured', async () => {
    const configService = {
      get: () => ({ appleSharedSecret: undefined }),
    } as unknown as ConfigService;
    const verifier = new ApplePurchaseVerifier(configService);

    expect(verifier.isConfigured).toBe(false);
    await expect(
      verifier.verify('receipt', 'com.projectascend.premium.monthly'),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
  });

  it('reports configured when a shared secret is present, without making a network call', () => {
    const configService = {
      get: () => ({ appleSharedSecret: 'test-secret' }),
    } as unknown as ConfigService;
    const verifier = new ApplePurchaseVerifier(configService);

    expect(verifier.isConfigured).toBe(true);
  });
});
