import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { CommunityReportsPage } from './CommunityReportsPage';

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

const sampleReport = {
  id: 'rep1',
  reporterId: 'u2',
  targetType: 'POST',
  targetId: 'post1',
  reason: 'Spam',
  status: 'OPEN',
  createdAt: '2026-01-01T00:00:00.000Z',
};

describe('CommunityReportsPage', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('lists open reports with action buttons', async () => {
    vi.mocked(fetch).mockResolvedValue(
      jsonResponse({
        data: { data: [sampleReport], meta: { page: 1, limit: 20, total: 1 } },
        meta: {},
        error: null,
      }),
    );

    render(<CommunityReportsPage />);

    await waitFor(() => expect(screen.getByText('Spam')).toBeInTheDocument());
    expect(screen.getByText('Mark reviewed')).toBeInTheDocument();
    expect(screen.getByText('Action & remove content')).toBeInTheDocument();
  });

  it('actioning a report calls the API and reloads the list', async () => {
    vi.mocked(fetch).mockImplementation((_input, init) => {
      if (init?.method === 'PATCH') {
        return Promise.resolve(
          jsonResponse({
            data: { ...sampleReport, status: 'REVIEWED' },
            meta: {},
            error: null,
          }),
        );
      }
      return Promise.resolve(
        jsonResponse({
          data: {
            data: [sampleReport],
            meta: { page: 1, limit: 20, total: 1 },
          },
          meta: {},
          error: null,
        }),
      );
    });

    render(<CommunityReportsPage />);
    await waitFor(() => expect(screen.getByText('Spam')).toBeInTheDocument());

    await userEvent.click(screen.getByText('Mark reviewed'));

    await waitFor(() =>
      expect(vi.mocked(fetch).mock.calls.some(([, init]) => init?.method === 'PATCH')).toBe(true),
    );
  });
});
