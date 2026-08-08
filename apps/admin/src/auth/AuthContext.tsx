import { createContext, useCallback, useContext, useMemo, useState } from 'react';
import type { ReactNode } from 'react';
import { adminApi } from '../api/adminApi';
import type { AdminPermission } from '../api/adminApi';
import { login as loginRequest } from '../api/authApi';
import type { AuthenticatedUser } from '../api/authApi';
import { setAccessToken } from '../api/client';

const SESSION_STORAGE_KEY = 'ascend-admin-session';

interface StoredSession {
  user: AuthenticatedUser;
  accessToken: string;
  // Granular admin RBAC (Build Session 9 Part 19) — fetched once at
  // login from the caller's own `/admin/me/permissions`, not decoded
  // from anything client-trusted. Every admin route still re-checks
  // this server-side; this only drives which nav items/actions render.
  permissions: AdminPermission[];
}

interface AuthContextValue {
  user: AuthenticatedUser | null;
  isAdmin: boolean;
  permissions: AdminPermission[];
  hasPermission: (permission: AdminPermission) => boolean;
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
  const initialStored = readStoredSession();
  const [user, setUser] = useState<AuthenticatedUser | null>(() => {
    if (initialStored) setAccessToken(initialStored.accessToken);
    return initialStored?.user ?? null;
  });
  const [permissions, setPermissions] = useState<AdminPermission[]>(
    initialStored?.permissions ?? [],
  );

  const login = useCallback(async (email: string, password: string) => {
    const response = await loginRequest(email, password);
    setAccessToken(response.tokens.accessToken);

    // Only an ADMIN-role account has any permission grants to fetch —
    // a MEMBER logging in here is rejected by RequireAdmin regardless.
    const grantedPermissions =
      response.user.role === 'ADMIN' ? (await adminApi.getMyPermissions()).permissions : [];

    sessionStorage.setItem(
      SESSION_STORAGE_KEY,
      JSON.stringify({
        user: response.user,
        accessToken: response.tokens.accessToken,
        permissions: grantedPermissions,
      }),
    );
    setUser(response.user);
    setPermissions(grantedPermissions);
  }, []);

  const logout = useCallback(() => {
    setAccessToken(null);
    sessionStorage.removeItem(SESSION_STORAGE_KEY);
    setUser(null);
    setPermissions([]);
  }, []);

  const hasPermission = useCallback(
    (permission: AdminPermission) => permissions.includes(permission),
    [permissions],
  );

  const value = useMemo<AuthContextValue>(
    () => ({ user, isAdmin: user?.role === 'ADMIN', permissions, hasPermission, login, logout }),
    [user, permissions, hasPermission, login, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within an AuthProvider');
  return context;
}
