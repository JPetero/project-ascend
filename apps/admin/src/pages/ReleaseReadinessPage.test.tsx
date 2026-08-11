import { render, screen, waitFor } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { ReleaseReadinessPage } from './ReleaseReadinessPage';

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

const sampleReadiness = {
  environment: 'production',
  security: {
    usingDevJwtSecrets: false,
    corsWildcard: false,
    productionSafe: true,
  },
  integrations: {
    mediaStorage: true,
    email: true,
    googleSignIn: true,
    appleSignIn: false,
    aiProvider: true,
    research: true,
    remotePush: true,
    appleIap: false,
    googleIap: true,
  },
  migrations: { upToDate: false, pending: ['20260101000000_example'] },
  featureFlags: { total: 4, enabled: 2 },
  items: [
    {
      key: 'database',
      label: 'Database',
      category: 'infrastructure',
      status: 'READY',
      detail: 'This check ran, which itself required a live database connection.',
    },
    {
      key: 'visionPhysicalDeviceQa',
      label: 'Vision physical-device QA',
      category: 'device-qa',
      status: 'DEVICE_QA_REQUIRED',
      detail: 'Run qa/vision-physical-device-checklist.md on real devices.',
    },
    {
      key: 'liveAi',
      label: 'Live Ascend AI',
      category: 'integrations',
      status: 'DISABLED',
      detail: 'LIVE_AI feature flag is off.',
    },
  ],
};

describe('ReleaseReadinessPage', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('renders the environment and readiness diagnostics', async () => {
    vi.mocked(fetch).mockResolvedValue(
      jsonResponse({ data: sampleReadiness, meta: {}, error: null }),
    );

    render(<ReleaseReadinessPage />);

    await waitFor(() => expect(screen.getByText('production')).toBeInTheDocument());
    expect(screen.getByText('2 of 4 enabled')).toBeInTheDocument();
    expect(screen.getByText('appleSignIn')).toBeInTheDocument();
    expect(screen.getByText('1 pending')).toBeInTheDocument();
    expect(screen.getByText('20260101000000_example')).toBeInTheDocument();
  });

  it('renders the beta readiness checklist items with status and detail (S14 Part 7)', async () => {
    vi.mocked(fetch).mockResolvedValue(
      jsonResponse({ data: sampleReadiness, meta: {}, error: null }),
    );

    render(<ReleaseReadinessPage />);

    await waitFor(() => expect(screen.getByText('Beta readiness checklist')).toBeInTheDocument());
    expect(screen.getByText('Vision physical-device QA')).toBeInTheDocument();
    expect(screen.getByText('DEVICE_QA_REQUIRED')).toBeInTheDocument();
    expect(
      screen.getByText('Run qa/vision-physical-device-checklist.md on real devices.'),
    ).toBeInTheDocument();
    expect(screen.getByText('DISABLED')).toBeInTheDocument();
  });

  it('shows "Up to date" with no pending list when every migration is applied', async () => {
    vi.mocked(fetch).mockResolvedValue(
      jsonResponse({
        data: { ...sampleReadiness, migrations: { upToDate: true, pending: [] } },
        meta: {},
        error: null,
      }),
    );

    render(<ReleaseReadinessPage />);

    await waitFor(() => expect(screen.getByText('Up to date')).toBeInTheDocument());
  });

  it('shows an error state on failure', async () => {
    vi.mocked(fetch).mockResolvedValue(
      jsonResponse({ data: null, meta: {}, error: { code: 'FORBIDDEN', message: 'Nope' } }, 403),
    );

    render(<ReleaseReadinessPage />);

    await waitFor(() => expect(screen.getByRole('alert')).toBeInTheDocument());
  });
});
