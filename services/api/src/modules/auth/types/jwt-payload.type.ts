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
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  tokenType: 'Bearer';
  expiresIn: string;
}
