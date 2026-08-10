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
  key: 'LIVE_AI',
  description: 'Live Ascend AI replies via a paid provider.',
  enabled: true,
  rolloutPercentage: 50,
  defaultEnabled: false,
  risk: 'RISKY_EXTERNAL',
  hasOverride: true,
  createdAt: '2026-01-01T00:00:00.000Z',
  updatedAt: '2026-01-01T00:00:00.000Z',
};

const registryOnlyFlag = {
  id: null,
  key: 'TRAINER_DASHBOARD',
  description: 'Trainer Dashboard entry icon.',
  enabled: true,
  rolloutPercentage: 100,
  defaultEnabled: true,
  risk: 'SAFE_CORE',
  hasOverride: false,
  createdAt: null,
  updatedAt: null,
};

describe('FeatureFlagsPage', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('lists feature flags with their risk and default behavior', async () => {
    vi.mocked(fetch).mockResolvedValue(
      jsonResponse({ data: [sampleFlag], meta: {}, error: null }),
    );

    render(<FeatureFlagsPage />);

    await waitFor(() => expect(screen.getByText('LIVE_AI')).toBeInTheDocument());
    expect(screen.getByText('Live Ascend AI replies via a paid provider.')).toBeInTheDocument();
    expect(screen.getByText('RISKY_EXTERNAL')).toBeInTheDocument();
    expect(screen.getByText('Closed')).toBeInTheDocument();
  });

  it('shows a registry entry with no override row, and no reset button for it', async () => {
    vi.mocked(fetch).mockResolvedValue(
      jsonResponse({ data: [registryOnlyFlag], meta: {}, error: null }),
    );

    render(<FeatureFlagsPage />);

    await waitFor(() => expect(screen.getByText('TRAINER_DASHBOARD')).toBeInTheDocument());
    expect(screen.getByText('SAFE_CORE')).toBeInTheDocument();
    expect(screen.getByText('Open')).toBeInTheDocument();
    expect(screen.queryByText('Reset to default')).not.toBeInTheDocument();
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
    await waitFor(() => expect(screen.getByText('LIVE_AI')).toBeInTheDocument());

    await userEvent.click(screen.getByLabelText('LIVE_AI enabled'));

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
    await waitFor(() => expect(screen.getByText('LIVE_AI')).toBeInTheDocument());

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

  it('resetting a flag with an override calls the delete endpoint', async () => {
    vi.mocked(fetch).mockImplementation((_input, init) => {
      if (init?.method === 'DELETE') {
        return Promise.resolve(jsonResponse({ data: null, meta: {}, error: null }));
      }
      return Promise.resolve(jsonResponse({ data: [sampleFlag], meta: {}, error: null }));
    });

    render(<FeatureFlagsPage />);
    await waitFor(() => expect(screen.getByText('Reset to default')).toBeInTheDocument());

    await userEvent.click(screen.getByText('Reset to default'));

    await waitFor(() =>
      expect(vi.mocked(fetch).mock.calls.some(([, init]) => init?.method === 'DELETE')).toBe(
        true,
      ),
    );
  });
});
