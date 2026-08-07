import { render, screen, waitFor } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import { App } from './App';

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

describe('App', () => {
  beforeEach(() => {
    sessionStorage.clear();
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('redirects an unauthenticated visitor to the login page', () => {
    render(
      <MemoryRouter initialEntries={['/support-tickets']}>
        <App />
      </MemoryRouter>,
    );

    expect(screen.getByText('Ascend Admin')).toBeInTheDocument();
    expect(screen.getByLabelText('Email')).toBeInTheDocument();
  });

  it('shows the not-authorized page for a signed-in non-admin', () => {
    sessionStorage.setItem(
      'ascend-admin-session',
      JSON.stringify({
        user: { id: 'u1', email: 'bea@example.com', role: 'MEMBER' },
        accessToken: 'tok',
      }),
    );

    render(
      <MemoryRouter initialEntries={['/support-tickets']}>
        <App />
      </MemoryRouter>,
    );

    expect(screen.getByText('Not authorized')).toBeInTheDocument();
  });

  it('shows the moderation queue navigation for a signed-in admin', async () => {
    sessionStorage.setItem(
      'ascend-admin-session',
      JSON.stringify({
        user: { id: 'u1', email: 'ada@example.com', role: 'ADMIN' },
        accessToken: 'tok',
      }),
    );
    vi.mocked(fetch).mockResolvedValue(
      jsonResponse({
        data: { data: [], meta: { page: 1, limit: 20, total: 0 } },
        meta: {},
        error: null,
      }),
    );

    render(
      <MemoryRouter initialEntries={['/support-tickets']}>
        <App />
      </MemoryRouter>,
    );

    await waitFor(() => expect(screen.getByText('Community reports')).toBeInTheDocument());
  });
});
