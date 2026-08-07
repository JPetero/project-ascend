import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as jwt from 'jsonwebtoken';
import jwksClient, { SigningKey } from 'jwks-rsa';
import { SocialAuthConfig } from '../../../config/configuration';
import { SocialIdentityVerifier, VerifiedSocialIdentity } from './social-identity.interface';

const APPLE_ISSUER = 'https://appleid.apple.com';
const APPLE_JWKS_URI = 'https://appleid.apple.com/auth/keys';

interface AppleIdTokenClaims {
  sub: string;
  email?: string;
  email_verified?: boolean | string;
}

/**
 * Verifies an Apple-issued ID token server-side against Apple's own
 * public keys (fetched via JWKS) — this needs no client secret, only
 * the Services ID / bundle id to validate the token's `aud` claim. No
 * live APPLE_CLIENT_ID exists in this environment (no Apple Developer
 * account has been configured this session), so this code path is real
 * but untested against a live Apple-issued token — see
 * build-session-9.md. Apple only includes the user's name in the very
 * first authorization response (not the ID token itself), which is why
 * `firstName` isn't populated here — the client must forward it
 * separately on first sign-in.
 */
@Injectable()
export class AppleTokenVerifier implements SocialIdentityVerifier {
  private readonly clientId: string | undefined;
  private client: jwksClient.JwksClient | undefined;

  constructor(private readonly configService: ConfigService) {
    this.clientId = this.configService.get<SocialAuthConfig>('socialAuth')!.appleClientId;
  }

  async verify(idToken: string): Promise<VerifiedSocialIdentity> {
    if (!this.clientId) {
      throw new UnauthorizedException('Apple sign-in is not configured.');
    }

    this.client ??= jwksClient({ jwksUri: APPLE_JWKS_URI });

    const getKey: jwt.GetPublicKeyOrSecret = (header, callback) => {
      this.client!.getSigningKey(header.kid, (error, key: SigningKey | undefined) => {
        callback(error, key?.getPublicKey());
      });
    };

    const claims = await new Promise<AppleIdTokenClaims>((resolve, reject) => {
      jwt.verify(
        idToken,
        getKey,
        { audience: this.clientId, issuer: APPLE_ISSUER, algorithms: ['RS256'] },
        (error, decoded) => {
          if (error || !decoded || typeof decoded === 'string') {
            reject(error ?? new Error('Malformed Apple ID token.'));
            return;
          }
          resolve(decoded as AppleIdTokenClaims);
        },
      );
    }).catch(() => {
      throw new UnauthorizedException('Apple sign-in token is invalid or expired.');
    });

    return {
      subject: claims.sub,
      email: claims.email ?? null,
      emailVerified: claims.email_verified === true || claims.email_verified === 'true',
    };
  }
}
