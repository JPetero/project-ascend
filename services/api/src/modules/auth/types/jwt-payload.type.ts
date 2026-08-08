import { UserRole } from '@prisma/client';

export interface JwtPayload {
  sub: string;
  email: string;
  // The RefreshToken family this access token descended from (Build
  // Session 10 Part 11). Optional so existing test-mock literals and any
  // access token issued before this field existed keep decoding — code
  // that needs to identify "the current session" (e.g. the sessions list's
  // `current` flag) must treat a missing familyId as "unknown", never as
  // a specific session.
  familyId?: string;
}

export interface AuthenticatedUser {
  id: string;
  email: string;
  // Read fresh from the DB on every request by JwtStrategy.validate —
  // never embedded in the JWT itself, so a role change (or an account
  // suspension) takes effect on the very next request instead of
  // waiting for the token to expire.
  role: UserRole;
  // Null until EmailVerificationToken confirmation (Build Session 9 Part
  // 4) — lets the client show a "verify your email" prompt.
  emailVerifiedAt: Date | null;
  // See JwtPayload.familyId.
  familyId?: string;
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  tokenType: 'Bearer';
  expiresIn: string;
}
