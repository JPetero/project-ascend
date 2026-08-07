import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { SupportTicketsPage } from './SupportTicketsPage';

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

describe('SupportTicketsPage', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('shows an empty state when there are no tickets for the filter', async () => {
    vi.mocked(fetch).mockResolvedValue(
      jsonResponse({
        data: { data: [], meta: { page: 1, limit: 20, total: 0 } },
        meta: {},
        error: null,
      }),
    );

    render(<SupportTicketsPage />);

    await waitFor(() =>
      expect(screen.getByText('No support tickets match this filter.')).toBeInTheDocument(),
    );
  });

  it('lists tickets returned by the API', async () => {
    vi.mocked(fetch).mockResolvedValue(
      jsonResponse({
        data: {
          data: [
            {
              id: 't1',
              userId: 'u1',
              category: 'BUG_REPORT',
              subject: 'App crashes on login',
              message: 'It crashes.',
              status: 'OPEN',
              createdAt: '2026-01-01T00:00:00.000Z',
              resolvedAt: null,
            },
          ],
          meta: { page: 1, limit: 20, total: 1 },
        },
        meta: {},
        error: null,
      }),
    );

    render(<SupportTicketsPage />);

    await waitFor(() => expect(screen.getByText('App crashes on login')).toBeInTheDocument());
  });

  it('re-fetches with the new status when the filter changes', async () => {
    vi.mocked(fetch).mockResolvedValue(
      jsonResponse({
        data: { data: [], meta: { page: 1, limit: 20, total: 0 } },
        meta: {},
        error: null,
      }),
    );

    render(<SupportTicketsPage />);
    await waitFor(() => expect(fetch).toHaveBeenCalledTimes(1));

    await userEvent.selectOptions(screen.getByLabelText('Status'), 'RESOLVED');

    await waitFor(() => expect(fetch).toHaveBeenCalledTimes(2));
    const [url] = vi.mocked(fetch).mock.calls[1];
    expect(String(url)).toContain('status=RESOLVED');
  });

  it('opens a ticket and submits a reply', async () => {
    vi.mocked(fetch).mockImplementation((input) => {
      const url = String(input);
      if (url.includes('/reply')) {
        return Promise.resolve(
          jsonResponse({
            data: {
              id: 'r1',
              ticketId: 't1',
              authorId: 'admin',
              isStaff: true,
              body: 'On it',
            },
            meta: {},
            error: null,
          }),
        );
      }
      if (url.includes('/support-tickets/t1')) {
        return Promise.resolve(
          jsonResponse({
            data: {
              id: 't1',
              userId: 'u1',
              category: 'BUG_REPORT',
              subject: 'App crashes on login',
              message: 'It crashes.',
              status: 'OPEN',
              createdAt: '2026-01-01T00:00:00.000Z',
              resolvedAt: null,
              replies: [],
            },
            meta: {},
            error: null,
          }),
        );
      }
      return Promise.resolve(
        jsonResponse({
          data: {
            data: [
              {
                id: 't1',
                userId: 'u1',
                category: 'BUG_REPORT',
                subject: 'App crashes on login',
                message: 'It crashes.',
                status: 'OPEN',
                createdAt: '2026-01-01T00:00:00.000Z',
                resolvedAt: null,
              },
            ],
            meta: { page: 1, limit: 20, total: 1 },
          },
          meta: {},
          error: null,
        }),
      );
    });

    render(<SupportTicketsPage />);
    await waitFor(() => expect(screen.getByText('App crashes on login')).toBeInTheDocument());

    await userEvent.click(screen.getByText('Open'));

    const dialog = await screen.findByRole('dialog', { name: 'Ticket detail' });
    await userEvent.type(within(dialog).getByLabelText('Reply'), 'On it');
    await userEvent.click(within(dialog).getByRole('button', { name: 'Send reply' }));

    await waitFor(() =>
      expect(vi.mocked(fetch).mock.calls.some(([url]) => String(url).includes('/reply'))).toBe(
        true,
      ),
    );
  });
});
