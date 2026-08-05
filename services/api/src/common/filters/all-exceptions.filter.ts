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
      exception instanceof HttpException ? exception.getStatus() : HttpStatus.INTERNAL_SERVER_ERROR;

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

    return {
      code: 'INTERNAL_SERVER_ERROR',
      message: 'Something went wrong. Please try again.',
    };
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
      default:
        return 'INTERNAL_SERVER_ERROR';
    }
  }
}
