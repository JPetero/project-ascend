import { createContext, useCallback, useContext, useMemo, useState } from 'react';
import type { ReactNode } from 'react';
import { login as loginRequest } from '../api/authApi';
import type { AuthenticatedUser } from '../api/authApi';
import { setAccessToken } from '../api/client';

const SESSION_STORAGE_KEY = 'ascend-admin-session';

interface StoredSession {
  user: AuthenticatedUser;
  accessToken: string;
}

interface AuthContextValue {
  user: AuthenticatedUser | null;
  isAdmin: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

function readStoredSession(): StoredSession | null {
  const raw = sessionStorage.getItem(SESSION_STORAGE_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as StoredSession;
  } catch {
    return null;
  }
}

/**
 * Session state for the admin app — Build Session 8 Part 17. Kept in
 * sessionStorage (cleared when the tab closes) rather than localStorage,
 * since an admin console session should not silently persist across
 * browser restarts. Deliberately does not implement refresh-token
 * rotation the way the mobile client does (see
 * SecureTokenStorage/ApiClient's retry-and-refresh interceptor) — an
 * expired access token here just signs the admin out and asks them to
 * log in again, which is an acceptable trade-off for a low-traffic
 * internal tool this session.
 */
export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthenticatedUser | null>(() => {
    const stored = readStoredSession();
    if (stored) setAccessToken(stored.accessToken);
    return stored?.user ?? null;
  });

  const login = useCallback(async (email: string, password: string) => {
    const response = await loginRequest(email, password);
    setAccessToken(response.tokens.accessToken);
    sessionStorage.setItem(
      SESSION_STORAGE_KEY,
      JSON.stringify({
        user: response.user,
        accessToken: response.tokens.accessToken,
      }),
    );
    setUser(response.user);
  }, []);

  const logout = useCallback(() => {
    setAccessToken(null);
    sessionStorage.removeItem(SESSION_STORAGE_KEY);
    setUser(null);
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({ user, isAdmin: user?.role === 'ADMIN', login, logout }),
    [user, login, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within an AuthProvider');
  return context;
}
