import { EventEmitter } from 'events';
import { requestLoggingMiddleware } from './request-logging.middleware';

function mockReqRes(headers: Record<string, string> = {}) {
  const req = {
    method: 'GET',
    originalUrl: '/feature-flags',
    header: (name: string) => headers[name.toLowerCase()],
  } as unknown as { id?: string };

  const emitter = new EventEmitter();
  const res = Object.assign(emitter, {
    statusCode: 200,
    setHeader: jest.fn(),
  });

  return { req, res };
}

describe('requestLoggingMiddleware', () => {
  it('generates a request id and echoes it as a response header when none was supplied', () => {
    const { req, res } = mockReqRes();
    const next = jest.fn();

    requestLoggingMiddleware(req as never, res as never, next);

    expect((req as { id: string }).id).toEqual(expect.any(String));
    expect((req as { id: string }).id.length).toBeGreaterThan(0);
    expect(res.setHeader).toHaveBeenCalledWith('X-Request-Id', (req as { id: string }).id);
    expect(next).toHaveBeenCalled();
  });

  it('reuses an incoming X-Request-Id instead of generating a new one', () => {
    const { req, res } = mockReqRes({ 'x-request-id': 'upstream-correlation-id' });
    const next = jest.fn();

    requestLoggingMiddleware(req as never, res as never, next);

    expect((req as { id: string }).id).toBe('upstream-correlation-id');
    expect(res.setHeader).toHaveBeenCalledWith('X-Request-Id', 'upstream-correlation-id');
  });

  it('logs a completion line once the response finishes', () => {
    const { req, res } = mockReqRes();
    const next = jest.fn();

    requestLoggingMiddleware(req as never, res as never, next);
    expect(() => res.emit('finish')).not.toThrow();
  });
});
