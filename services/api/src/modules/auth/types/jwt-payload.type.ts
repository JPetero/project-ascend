import { UserRole } from '@prisma/client';

export interface JwtPayload {
  sub: string;
  email: string;
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
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  tokenType: 'Bearer';
  expiresIn: string;
}
