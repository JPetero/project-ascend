import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';
import { SocialAuthConfig } from '../../../config/configuration';
import { SocialIdentityVerifier, VerifiedSocialIdentity } from './social-identity.interface';

/**
 * Verifies a Google-issued ID token server-side against Google's own
 * public keys (fetched by google-auth-library) — this needs no client
 * secret, only the OAuth client id to validate the token's `aud` claim.
 * No live GOOGLE_OAUTH_CLIENT_ID exists in this environment (no Google
 * Cloud project has been created this session), so this code path is
 * real but untested against a live Google-issued token — see
 * build-session-9.md.
 */
@Injectable()
export class GoogleTokenVerifier implements SocialIdentityVerifier {
  private readonly clientId: string | undefined;
  private client: OAuth2Client | undefined;

  constructor(private readonly configService: ConfigService) {
    this.clientId = this.configService.get<SocialAuthConfig>('socialAuth')!.googleClientId;
  }

  async verify(idToken: string): Promise<VerifiedSocialIdentity> {
    if (!this.clientId) {
      throw new UnauthorizedException('Google sign-in is not configured.');
    }

    this.client ??= new OAuth2Client(this.clientId);

    let payload;
    try {
      const ticket = await this.client.verifyIdToken({ idToken, audience: this.clientId });
      payload = ticket.getPayload();
    } catch {
      throw new UnauthorizedException('Google sign-in token is invalid or expired.');
    }

    if (!payload?.sub) {
      throw new UnauthorizedException('Google sign-in token is invalid or expired.');
    }

    return {
      subject: payload.sub,
      email: payload.email ?? null,
      emailVerified: payload.email_verified ?? false,
      firstName: payload.given_name,
    };
  }
}
