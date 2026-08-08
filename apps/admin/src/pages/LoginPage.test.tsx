import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { AuthProvider } from '../auth/AuthContext';
import { LoginPage } from './LoginPage';

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function renderLoginPage() {
  return render(
    <AuthProvider>
      <MemoryRouter initialEntries={['/login']}>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/support-tickets" element={<p>Support tickets page</p>} />
        </Routes>
      </MemoryRouter>
    </AuthProvider>,
  );
}

describe('LoginPage', () => {
  beforeEach(() => {
    sessionStorage.clear();
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('navigates to the support tickets page on successful login', async () => {
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
          data: { userId: 'u1', permissions: ['MANAGE_SUPPORT'] },
          meta: {},
          error: null,
        }),
      );
    renderLoginPage();

    await userEvent.type(screen.getByLabelText('Email'), 'ada@example.com');
    await userEvent.type(screen.getByLabelText('Password'), 'Str0ngPass!');
    await userEvent.click(screen.getByRole('button', { name: 'Sign in' }));

    await waitFor(() => expect(screen.getByText('Support tickets page')).toBeInTheDocument());
  });

  it('shows the server error message on failed login', async () => {
    vi.mocked(fetch).mockResolvedValueOnce(
      jsonResponse(
        {
          data: null,
          meta: {},
          error: {
            code: 'UNAUTHORIZED',
            message: 'Invalid email or password.',
          },
        },
        401,
      ),
    );
    renderLoginPage();

    await userEvent.type(screen.getByLabelText('Email'), 'ada@example.com');
    await userEvent.type(screen.getByLabelText('Password'), 'wrong');
    await userEvent.click(screen.getByRole('button', { name: 'Sign in' }));

    await waitFor(() => expect(screen.getByText('Invalid email or password.')).toBeInTheDocument());
  });
});
