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
  featureFlags: { total: 4, enabled: 2 },
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
  });

  it('shows an error state on failure', async () => {
    vi.mocked(fetch).mockResolvedValue(
      jsonResponse({ data: null, meta: {}, error: { code: 'FORBIDDEN', message: 'Nope' } }, 403),
    );

    render(<ReleaseReadinessPage />);

    await waitFor(() => expect(screen.getByRole('alert')).toBeInTheDocument());
  });
});
