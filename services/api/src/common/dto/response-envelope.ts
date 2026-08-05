export interface ResponseEnvelope<T> {
  data: T | null;
  meta: Record<string, unknown>;
  error: {
    code: string;
    message: string;
    details?: Record<string, unknown>;
  } | null;
}
