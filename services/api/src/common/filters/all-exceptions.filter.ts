import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { ResponseEnvelope } from '../dto/response-envelope';

interface HttpExceptionBody {
  message?: string | string[];
  error?: string;
  code?: string;
}

/**
 * Converts every thrown error into the shared response envelope and
 * never leaks raw exception details (stack traces, driver errors) to clients.
 */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger('ExceptionFilter');

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : (this.statusFromRawError(exception) ?? HttpStatus.INTERNAL_SERVER_ERROR);

    const { code, message, details } = this.resolveErrorShape(exception, status);

    if (status >= HttpStatus.INTERNAL_SERVER_ERROR) {
      this.logger.error(
        `${request.method} ${request.url} -> ${status}`,
        exception instanceof Error ? exception.stack : undefined,
      );
    }

    const body: ResponseEnvelope<null> = {
      data: null,
      meta: {},
      error: { code, message, details },
    };

    response.status(status).json(body);
  }

  private resolveErrorShape(
    exception: unknown,
    status: number,
  ): { code: string; message: string; details?: Record<string, unknown> } {
    if (exception instanceof HttpException) {
      const body = exception.getResponse();

      if (typeof body === 'string') {
        return { code: this.codeForStatus(status), message: body };
      }

      const typedBody = body as HttpExceptionBody;
      const message = Array.isArray(typedBody.message)
        ? typedBody.message.join(' ')
        : (typedBody.message ?? exception.message);

      return {
        code: typedBody.code ?? this.codeForStatus(status),
        message,
        details: Array.isArray(typedBody.message) ? { fields: typedBody.message } : undefined,
      };
    }

    // A raw (non-HttpException) error whose own status was already
    // resolved to a 4xx by statusFromRawError below — e.g. Express's
    // body-parser rejecting an oversized request body before it ever
    // reaches Nest's validation pipeline. Its message is safe to surface
    // (it describes the client's mistake, not an internal detail) unlike
    // a genuine 500, which stays generic.
    if (status >= HttpStatus.BAD_REQUEST && status < HttpStatus.INTERNAL_SERVER_ERROR) {
      const message = exception instanceof Error ? exception.message : 'Invalid request.';
      return { code: this.codeForStatus(status), message };
    }

    return {
      code: 'INTERNAL_SERVER_ERROR',
      message: 'Something went wrong. Please try again.',
    };
  }

  /** Body-parser (and other Express/Connect middleware) throws a plain
   * `Error` with a `.status`/`.statusCode` property rather than a Nest
   * `HttpException` — e.g. `PayloadTooLargeError` (413) when a request
   * body exceeds the configured size limit, which happens before Nest's
   * own DTO validation ever runs. Without this, every such error fell
   * through to a generic 500 instead of the 4xx it actually is. */
  private statusFromRawError(exception: unknown): number | undefined {
    if (!exception || typeof exception !== 'object') return undefined;
    const raw = exception as { status?: unknown; statusCode?: unknown };
    const status = typeof raw.status === 'number' ? raw.status : raw.statusCode;
    return typeof status === 'number' && status >= 400 && status < 500 ? status : undefined;
  }

  private codeForStatus(status: number): string {
    switch (status) {
      case HttpStatus.BAD_REQUEST:
        return 'VALIDATION_ERROR';
      case HttpStatus.UNAUTHORIZED:
        return 'UNAUTHORIZED';
      case HttpStatus.FORBIDDEN:
        return 'FORBIDDEN';
      case HttpStatus.NOT_FOUND:
        return 'NOT_FOUND';
      case HttpStatus.CONFLICT:
        return 'CONFLICT';
      case HttpStatus.TOO_MANY_REQUESTS:
        return 'RATE_LIMITED';
      case HttpStatus.PAYLOAD_TOO_LARGE:
        return 'PAYLOAD_TOO_LARGE';
      default:
        return 'INTERNAL_SERVER_ERROR';
    }
  }
}
