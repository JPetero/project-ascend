import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { FeatureFlagsPage } from './FeatureFlagsPage';

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

const sampleFlag = {
  id: 'flag1',
  key: 'new_dashboard',
  description: 'Rolls out the redesigned dashboard',
  enabled: true,
  rolloutPercentage: 50,
  createdAt: '2026-01-01T00:00:00.000Z',
  updatedAt: '2026-01-01T00:00:00.000Z',
};

describe('FeatureFlagsPage', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('lists feature flags', async () => {
    vi.mocked(fetch).mockResolvedValue(
      jsonResponse({ data: [sampleFlag], meta: {}, error: null }),
    );

    render(<FeatureFlagsPage />);

    await waitFor(() => expect(screen.getByText('new_dashboard')).toBeInTheDocument());
    expect(screen.getByText('Rolls out the redesigned dashboard')).toBeInTheDocument();
  });

  it('toggling enabled calls the upsert endpoint', async () => {
    vi.mocked(fetch).mockImplementation((_input, init) => {
      if (init?.method === 'POST') {
        return Promise.resolve(
          jsonResponse({ data: { ...sampleFlag, enabled: false }, meta: {}, error: null }),
        );
      }
      return Promise.resolve(jsonResponse({ data: [sampleFlag], meta: {}, error: null }));
    });

    render(<FeatureFlagsPage />);
    await waitFor(() => expect(screen.getByText('new_dashboard')).toBeInTheDocument());

    await userEvent.click(screen.getByLabelText('new_dashboard enabled'));

    await waitFor(() =>
      expect(vi.mocked(fetch).mock.calls.some(([, init]) => init?.method === 'POST')).toBe(true),
    );
  });

  it('creating a flag calls the upsert endpoint with the new key', async () => {
    vi.mocked(fetch).mockImplementation((_input, init) => {
      if (init?.method === 'POST') {
        return Promise.resolve(
          jsonResponse({
            data: { ...sampleFlag, key: 'brand_new_flag' },
            meta: {},
            error: null,
          }),
        );
      }
      return Promise.resolve(jsonResponse({ data: [sampleFlag], meta: {}, error: null }));
    });

    render(<FeatureFlagsPage />);
    await waitFor(() => expect(screen.getByText('new_dashboard')).toBeInTheDocument());

    await userEvent.type(screen.getByLabelText('New flag key'), 'brand_new_flag');
    await userEvent.click(screen.getByText('Create'));

    await waitFor(() =>
      expect(
        vi
          .mocked(fetch)
          .mock.calls.some(
            ([url, init]) =>
              init?.method === 'POST' && String(url).includes('brand_new_flag'),
          ),
      ).toBe(true),
    );
  });

  it('deleting a flag calls the delete endpoint', async () => {
    vi.mocked(fetch).mockImplementation((_input, init) => {
      if (init?.method === 'DELETE') {
        return Promise.resolve(jsonResponse({ data: null, meta: {}, error: null }));
      }
      return Promise.resolve(jsonResponse({ data: [sampleFlag], meta: {}, error: null }));
    });

    render(<FeatureFlagsPage />);
    await waitFor(() => expect(screen.getByText('Delete')).toBeInTheDocument());

    await userEvent.click(screen.getByText('Delete'));

    await waitFor(() =>
      expect(vi.mocked(fetch).mock.calls.some(([, init]) => init?.method === 'DELETE')).toBe(
        true,
      ),
    );
  });
});
