import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { apiClient, ApiError, setAccessToken } from './client';

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

describe('apiClient', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn());
    setAccessToken(null);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('unwraps the response envelope on success', async () => {
    vi.mocked(fetch).mockResolvedValueOnce(
      jsonResponse({ data: { id: '1' }, meta: {}, error: null }),
    );

    const result = await apiClient.get<{ id: string }>('/admin/support-tickets');

    expect(result).toEqual({ id: '1' });
  });

  it('throws an ApiError using the envelope error message', async () => {
    vi.mocked(fetch).mockResolvedValueOnce(
      jsonResponse(
        {
          data: null,
          meta: {},
          error: { code: 'FORBIDDEN', message: 'Admin access required.' },
        },
        403,
      ),
    );

    await expect(apiClient.get('/admin/support-tickets')).rejects.toMatchObject({
      message: 'Admin access required.',
      status: 403,
      code: 'FORBIDDEN',
    });
  });

  it('throws an ApiError instance', async () => {
    vi.mocked(fetch).mockResolvedValueOnce(
      jsonResponse({ data: null, meta: {}, error: { code: 'X', message: 'nope' } }, 400),
    );

    await expect(apiClient.get('/x')).rejects.toBeInstanceOf(ApiError);
  });

  it('attaches the bearer token once set', async () => {
    setAccessToken('token-123');
    vi.mocked(fetch).mockResolvedValueOnce(jsonResponse({ data: [], meta: {}, error: null }));

    await apiClient.get('/admin/support-tickets');

    const [, options] = vi.mocked(fetch).mock.calls[0];
    expect((options?.headers as Record<string, string>).Authorization).toBe('Bearer token-123');
  });

  it('omits query params whose value is undefined', async () => {
    vi.mocked(fetch).mockResolvedValueOnce(jsonResponse({ data: [], meta: {}, error: null }));

    await apiClient.get('/admin/support-tickets', { status: undefined });

    const [url] = vi.mocked(fetch).mock.calls[0];
    expect(String(url)).not.toContain('status');
  });
});
