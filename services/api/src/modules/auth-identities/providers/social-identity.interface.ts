/**
 * Build Session 9 Part 8 — the result of successfully verifying a
 * provider-issued ID token server-side. `subject` is the provider's
 * stable user id (never the email — emails can change), `emailVerified`
 * reflects the provider's own claim, which this app trusts as proof of
 * email ownership independent of Ascend's own email-verification flow.
 */
export interface VerifiedSocialIdentity {
  subject: string;
  email: string | null;
  emailVerified: boolean;
  firstName?: string;
}

export interface SocialIdentityVerifier {
  /** Throws if the token is invalid, expired, or the provider is not configured. */
  verify(idToken: string): Promise<VerifiedSocialIdentity>;
}
