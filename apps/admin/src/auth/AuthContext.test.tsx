import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { AuthProvider, useAuth } from './AuthContext';

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function Probe() {
  const { user, isAdmin, permissions, login, logout } = useAuth();
  return (
    <div>
      <p>{user ? `signed in as ${user.email} (${isAdmin ? 'admin' : 'member'})` : 'signed out'}</p>
      <p>permissions: {permissions.join(',') || 'none'}</p>
      <button onClick={() => login('ada@example.com', 'pw')}>Login</button>
      <button onClick={logout}>Logout</button>
    </div>
  );
}

describe('AuthProvider', () => {
  beforeEach(() => {
    sessionStorage.clear();
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('starts signed out and persists the session (including its permission grants) on login', async () => {
    vi.mocked(fetch)
      .mockResolvedValueOnce(
        jsonResponse({
          data: {
            user: { id: 'u1', email: 'ada@example.com', role: 'ADMIN' },
            tokens: {
              accessToken: 'tok',
              refreshToken: 'r',
              tokenType: 'Bearer',
              expiresIn: '15m',
            },
          },
          meta: {},
          error: null,
        }),
      )
      .mockResolvedValueOnce(
        jsonResponse({
          data: { userId: 'u1', permissions: ['MODERATE_COMMUNITY'] },
          meta: {},
          error: null,
        }),
      );

    render(
      <AuthProvider>
        <Probe />
      </AuthProvider>,
    );
    expect(screen.getByText('signed out')).toBeInTheDocument();

    await userEvent.click(screen.getByText('Login'));

    await waitFor(() =>
      expect(screen.getByText('signed in as ada@example.com (admin)')).toBeInTheDocument(),
    );
    expect(screen.getByText('permissions: MODERATE_COMMUNITY')).toBeInTheDocument();
    expect(sessionStorage.getItem('ascend-admin-session')).toContain('ada@example.com');
    expect(sessionStorage.getItem('ascend-admin-session')).toContain('MODERATE_COMMUNITY');
  });

  it('never fetches permissions for a MEMBER login', async () => {
    vi.mocked(fetch).mockResolvedValueOnce(
      jsonResponse({
        data: {
          user: { id: 'u2', email: 'bea@example.com', role: 'MEMBER' },
          tokens: {
            accessToken: 'tok',
            refreshToken: 'r',
            tokenType: 'Bearer',
            expiresIn: '15m',
          },
        },
        meta: {},
        error: null,
      }),
    );

    render(
      <AuthProvider>
        <Probe />
      </AuthProvider>,
    );
    await userEvent.click(screen.getByText('Login'));

    await waitFor(() =>
      expect(screen.getByText('signed in as bea@example.com (member)')).toBeInTheDocument(),
    );
    expect(fetch).toHaveBeenCalledTimes(1);
    expect(screen.getByText('permissions: none')).toBeInTheDocument();
  });

  it('restores a session already in sessionStorage on mount', () => {
    sessionStorage.setItem(
      'ascend-admin-session',
      JSON.stringify({
        user: { id: 'u1', email: 'bea@example.com', role: 'MEMBER' },
        accessToken: 'tok',
      }),
    );

    render(
      <AuthProvider>
        <Probe />
      </AuthProvider>,
    );

    expect(screen.getByText('signed in as bea@example.com (member)')).toBeInTheDocument();
  });

  it('logout clears the session', async () => {
    sessionStorage.setItem(
      'ascend-admin-session',
      JSON.stringify({
        user: { id: 'u1', email: 'bea@example.com', role: 'ADMIN' },
        accessToken: 'tok',
      }),
    );

    render(
      <AuthProvider>
        <Probe />
      </AuthProvider>,
    );
    await userEvent.click(screen.getByText('Logout'));

    expect(screen.getByText('signed out')).toBeInTheDocument();
    expect(sessionStorage.getItem('ascend-admin-session')).toBeNull();
  });
});
