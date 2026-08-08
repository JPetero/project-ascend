// Thin fetch wrapper over services/api's shared { data, meta, error }
// response envelope — Build Session 8 Part 17. Deliberately not a
// generated client: the admin app only ever calls the small, fixed set
// of endpoints under /admin plus /auth/login, so a hand-written wrapper
// stays easier to read than generated boilerplate.

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:3000';

export class ApiError extends Error {
  constructor(
    message: string,
    public readonly status: number,
    public readonly code: string,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

interface ResponseEnvelope<T> {
  data: T | null;
  meta: Record<string, unknown>;
  error: { code: string; message: string } | null;
}

let accessToken: string | null = null;

export function setAccessToken(token: string | null): void {
  accessToken = token;
}

async function request<T>(
  path: string,
  options: {
    method?: string;
    body?: unknown;
    query?: Record<string, string | undefined>;
  } = {},
): Promise<T> {
  const url = new URL(path, API_BASE_URL);
  for (const [key, value] of Object.entries(options.query ?? {})) {
    if (value !== undefined && value !== '') url.searchParams.set(key, value);
  }

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };
  if (accessToken) headers.Authorization = `Bearer ${accessToken}`;

  const response = await fetch(url, {
    method: options.method ?? 'GET',
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
  });

  let envelope: ResponseEnvelope<T>;
  try {
    envelope = (await response.json()) as ResponseEnvelope<T>;
  } catch {
    throw new ApiError(
      'The server returned an unreadable response.',
      response.status,
      'BAD_RESPONSE',
    );
  }

  if (!response.ok || envelope.error) {
    throw new ApiError(
      envelope.error?.message ?? 'Something went wrong.',
      response.status,
      envelope.error?.code ?? 'UNKNOWN',
    );
  }

  return envelope.data as T;
}

export const apiClient = {
  get: <T>(path: string, query?: Record<string, string | undefined>) => request<T>(path, { query }),
  post: <T>(path: string, body?: unknown) => request<T>(path, { method: 'POST', body }),
  patch: <T>(path: string, body?: unknown) => request<T>(path, { method: 'PATCH', body }),
  delete: <T>(path: string) => request<T>(path, { method: 'DELETE' }),
};
