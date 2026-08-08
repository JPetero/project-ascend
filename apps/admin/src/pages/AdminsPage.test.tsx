import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { AdminsPage } from './AdminsPage';

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

const sampleAdmins = [
  { id: 'admin1', email: 'staff@example.com', permissions: ['MODERATE_COMMUNITY'] },
  { id: 'admin2', email: 'newbie@example.com', permissions: [] },
];

describe('AdminsPage', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('lists admins with their current permission grants', async () => {
    vi.mocked(fetch).mockResolvedValue(
      jsonResponse({ data: sampleAdmins, meta: {}, error: null }),
    );

    render(<AdminsPage />);

    await waitFor(() => expect(screen.getByText('staff@example.com')).toBeInTheDocument());
    expect(
      screen.getByLabelText('Revoke MODERATE_COMMUNITY from staff@example.com'),
    ).toBeInTheDocument();
    expect(screen.getByText('No permissions granted')).toBeInTheDocument();
  });

  it('granting a permission POSTs it and reloads the list', async () => {
    vi.mocked(fetch).mockImplementation((_input, init) => {
      if (init?.method === 'POST') {
        return Promise.resolve(
          jsonResponse({
            data: { userId: 'admin2', permissions: ['MANAGE_SUPPORT'] },
            meta: {},
            error: null,
          }),
        );
      }
      return Promise.resolve(jsonResponse({ data: sampleAdmins, meta: {}, error: null }));
    });

    render(<AdminsPage />);
    await waitFor(() => expect(screen.getByText('newbie@example.com')).toBeInTheDocument());

    const grantButtons = screen.getAllByText('Grant');
    await userEvent.click(grantButtons[1]);

    await waitFor(() => {
      const postCall = vi.mocked(fetch).mock.calls.find(([, init]) => init?.method === 'POST');
      expect(postCall).toBeDefined();
      expect(String(postCall?.[0])).toContain('/admin/admins/admin2/permissions');
    });
  });

  it('revoking a permission DELETEs it and reloads the list', async () => {
    vi.mocked(fetch).mockImplementation((_input, init) => {
      if (init?.method === 'DELETE') {
        return Promise.resolve(
          jsonResponse({ data: { userId: 'admin1', permissions: [] }, meta: {}, error: null }),
        );
      }
      return Promise.resolve(jsonResponse({ data: sampleAdmins, meta: {}, error: null }));
    });

    render(<AdminsPage />);
    await waitFor(() =>
      expect(
        screen.getByLabelText('Revoke MODERATE_COMMUNITY from staff@example.com'),
      ).toBeInTheDocument(),
    );

    await userEvent.click(screen.getByLabelText('Revoke MODERATE_COMMUNITY from staff@example.com'));

    await waitFor(() => {
      const deleteCall = vi.mocked(fetch).mock.calls.find(([, init]) => init?.method === 'DELETE');
      expect(deleteCall).toBeDefined();
      expect(String(deleteCall?.[0])).toContain(
        '/admin/admins/admin1/permissions/MODERATE_COMMUNITY',
      );
    });
  });

  it('shows an empty state when no ADMIN-role accounts exist', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({ data: [], meta: {}, error: null }));

    render(<AdminsPage />);

    await waitFor(() =>
      expect(screen.getByText('No ADMIN-role accounts exist yet.')).toBeInTheDocument(),
    );
  });
});
