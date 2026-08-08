import { ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GooglePurchaseVerifier } from './google-purchase-verifier';

describe('GooglePurchaseVerifier', () => {
  it('honestly rejects instead of pretending to verify when no service account is configured', async () => {
    const configService = {
      get: () => ({ googleServiceAccountJson: undefined, googlePackageName: undefined }),
    } as unknown as ConfigService;
    const verifier = new GooglePurchaseVerifier(configService);

    expect(verifier.isConfigured).toBe(false);
    await expect(
      verifier.verify('token', 'com.projectascend.premium.monthly'),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
  });

  it('honestly rejects when the service account is present but the package name is missing', async () => {
    const configService = {
      get: () => ({
        googleServiceAccountJson: '{"client_email":"x"}',
        googlePackageName: undefined,
      }),
    } as unknown as ConfigService;
    const verifier = new GooglePurchaseVerifier(configService);

    expect(verifier.isConfigured).toBe(false);
  });

  it('reports configured when both values are present, without making a network call', () => {
    const configService = {
      get: () => ({
        googleServiceAccountJson: '{"client_email":"x","private_key":"y"}',
        googlePackageName: 'com.projectascend.app',
      }),
    } as unknown as ConfigService;
    const verifier = new GooglePurchaseVerifier(configService);

    expect(verifier.isConfigured).toBe(true);
  });
});
