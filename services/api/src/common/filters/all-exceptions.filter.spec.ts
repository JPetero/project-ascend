import { ArgumentsHost, BadRequestException, HttpStatus } from '@nestjs/common';
import { AllExceptionsFilter } from './all-exceptions.filter';

function mockHost() {
  const json = jest.fn();
  const status = jest.fn(() => ({ json }));
  const response = { status };
  const request = { method: 'POST', url: '/health-metrics/sync' };
  const host = {
    switchToHttp: () => ({
      getResponse: () => response,
      getRequest: () => request,
    }),
  } as unknown as ArgumentsHost;
  return { host, status, json };
}

describe('AllExceptionsFilter', () => {
  let filter: AllExceptionsFilter;

  beforeEach(() => {
    filter = new AllExceptionsFilter();
  });

  it('maps a NestJS HttpException to its own status and message', () => {
    const { host, status, json } = mockHost();

    filter.catch(new BadRequestException('bad input'), host);

    expect(status).toHaveBeenCalledWith(HttpStatus.BAD_REQUEST);
    expect(json).toHaveBeenCalledWith({
      data: null,
      meta: {},
      error: { code: 'VALIDATION_ERROR', message: 'bad input', details: undefined },
    });
  });

  it('maps a raw (non-HttpException) error with a 4xx status — e.g. body-parser rejecting an oversized request — to that status, not a generic 500', () => {
    const { host, status, json } = mockHost();
    const payloadTooLarge = Object.assign(new Error('request entity too large'), {
      status: 413,
      type: 'entity.too.large',
    });

    filter.catch(payloadTooLarge, host);

    expect(status).toHaveBeenCalledWith(413);
    expect(json).toHaveBeenCalledWith({
      data: null,
      meta: {},
      error: {
        code: 'PAYLOAD_TOO_LARGE',
        message: 'request entity too large',
        details: undefined,
      },
    });
  });

  it('supports statusCode as well as status on a raw error', () => {
    const { host, status } = mockHost();
    const rawError = Object.assign(new Error('nope'), { statusCode: 404 });

    filter.catch(rawError, host);

    expect(status).toHaveBeenCalledWith(404);
  });

  it('still falls back to a generic 500 for a truly unknown error, never leaking its message', () => {
    const { host, status, json } = mockHost();

    filter.catch(new Error('a raw database connection string leaked here'), host);

    expect(status).toHaveBeenCalledWith(HttpStatus.INTERNAL_SERVER_ERROR);
    expect(json).toHaveBeenCalledWith({
      data: null,
      meta: {},
      error: {
        code: 'INTERNAL_SERVER_ERROR',
        message: 'Something went wrong. Please try again.',
      },
    });
  });

  it('ignores an out-of-range numeric status on a raw error (e.g. 500-599) and still treats it as an unknown 500', () => {
    const { host, status, json } = mockHost();
    const rawError = Object.assign(new Error('upstream exploded'), { status: 502 });

    filter.catch(rawError, host);

    expect(status).toHaveBeenCalledWith(HttpStatus.INTERNAL_SERVER_ERROR);
    expect(json).toHaveBeenCalledWith(
      expect.objectContaining({
        error: expect.objectContaining({ code: 'INTERNAL_SERVER_ERROR' }),
      }),
    );
  });
});
