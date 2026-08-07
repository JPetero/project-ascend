import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { PromotedCampaignsPage } from './PromotedCampaignsPage';

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

const sampleCampaign = {
  id: 'camp1',
  creatorId: 'u3',
  postId: 'post1',
  status: 'PENDING_REVIEW',
  createdAt: '2026-01-01T00:00:00.000Z',
};

describe('PromotedCampaignsPage', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('lists pending-review campaigns with Approve/Reject actions', async () => {
    vi.mocked(fetch).mockResolvedValue(
      jsonResponse({
        data: {
          data: [sampleCampaign],
          meta: { page: 1, limit: 20, total: 1 },
        },
        meta: {},
        error: null,
      }),
    );

    render(<PromotedCampaignsPage />);

    await waitFor(() => expect(screen.getByText('post1')).toBeInTheDocument());
    expect(screen.getByText('Approve')).toBeInTheDocument();
    expect(screen.getByText('Reject')).toBeInTheDocument();
  });

  it('rejecting a campaign calls the API with REJECTED', async () => {
    vi.mocked(fetch).mockImplementation((_input, init) => {
      if (init?.method === 'PATCH') {
        return Promise.resolve(
          jsonResponse({
            data: { ...sampleCampaign, status: 'REJECTED' },
            meta: {},
            error: null,
          }),
        );
      }
      return Promise.resolve(
        jsonResponse({
          data: {
            data: [sampleCampaign],
            meta: { page: 1, limit: 20, total: 1 },
          },
          meta: {},
          error: null,
        }),
      );
    });

    render(<PromotedCampaignsPage />);
    await waitFor(() => expect(screen.getByText('Reject')).toBeInTheDocument());

    await userEvent.click(screen.getByText('Reject'));

    await waitFor(() => {
      const patchCall = vi.mocked(fetch).mock.calls.find(([, init]) => init?.method === 'PATCH');
      expect(patchCall).toBeDefined();
      expect(JSON.parse(String(patchCall?.[1]?.body))).toEqual({
        status: 'REJECTED',
      });
    });
  });
});
