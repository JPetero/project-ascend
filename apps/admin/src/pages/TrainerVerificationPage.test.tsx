import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { TrainerVerificationPage } from './TrainerVerificationPage';

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

const sampleApplication = {
  id: 'app1',
  userId: 'u2',
  credentials: 'NASM-certified personal trainer, 5 years experience.',
  status: 'PENDING',
  submittedAt: '2026-01-01T00:00:00.000Z',
  reviewedAt: null,
};

describe('TrainerVerificationPage', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('lists pending applications with Approve/Reject actions', async () => {
    vi.mocked(fetch).mockResolvedValue(
      jsonResponse({
        data: {
          data: [sampleApplication],
          meta: { page: 1, limit: 20, total: 1 },
        },
        meta: {},
        error: null,
      }),
    );

    render(<TrainerVerificationPage />);

    await waitFor(() =>
      expect(
        screen.getByText('NASM-certified personal trainer, 5 years experience.'),
      ).toBeInTheDocument(),
    );
    expect(screen.getByText('Approve')).toBeInTheDocument();
    expect(screen.getByText('Reject')).toBeInTheDocument();
  });

  it('approving an application calls the API', async () => {
    vi.mocked(fetch).mockImplementation((_input, init) => {
      if (init?.method === 'PATCH') {
        return Promise.resolve(
          jsonResponse({
            data: { ...sampleApplication, status: 'APPROVED' },
            meta: {},
            error: null,
          }),
        );
      }
      return Promise.resolve(
        jsonResponse({
          data: {
            data: [sampleApplication],
            meta: { page: 1, limit: 20, total: 1 },
          },
          meta: {},
          error: null,
        }),
      );
    });

    render(<TrainerVerificationPage />);
    await waitFor(() => expect(screen.getByText('Approve')).toBeInTheDocument());

    await userEvent.click(screen.getByText('Approve'));

    await waitFor(() =>
      expect(vi.mocked(fetch).mock.calls.some(([, init]) => init?.method === 'PATCH')).toBe(true),
    );
  });
});
