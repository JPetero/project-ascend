import { UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppleTokenVerifier } from './apple-token-verifier';

describe('AppleTokenVerifier', () => {
  it('honestly rejects instead of pretending to verify when no client id is configured', async () => {
    const configService = { get: () => ({ appleClientId: undefined }) } as unknown as ConfigService;
    const verifier = new AppleTokenVerifier(configService);

    await expect(verifier.verify('any-token')).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
