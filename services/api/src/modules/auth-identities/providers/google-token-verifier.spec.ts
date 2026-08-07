import { UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleTokenVerifier } from './google-token-verifier';

describe('GoogleTokenVerifier', () => {
  it('honestly rejects instead of pretending to verify when no client id is configured', async () => {
    const configService = {
      get: () => ({ googleClientId: undefined }),
    } as unknown as ConfigService;
    const verifier = new GoogleTokenVerifier(configService);

    await expect(verifier.verify('any-token')).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
