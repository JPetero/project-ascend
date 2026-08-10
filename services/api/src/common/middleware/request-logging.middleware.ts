import { randomUUID } from 'crypto';
import { Logger } from '@nestjs/common';
import { NextFunction, Request, Response } from 'express';

const logger = new Logger('HTTP');

/**
 * Build Session 12 Part 15-17 — observability foundation. Every request
 * gets a correlation id (reusing an incoming `X-Request-Id` if a gateway
 * already set one, so a trace can span multiple hops) that's echoed back
 * on the response and logged alongside method/path/status/duration on
 * completion. AllExceptionsFilter reads the same id off the request so a
 * 5xx's error log line can be tied back to this completion log line —
 * this is intentionally a foundation (correlation + structured logging)
 * for a future APM/log-aggregation integration, not a full observability
 * platform itself.
 */
export interface RequestWithId extends Request {
  id: string;
}

export function requestLoggingMiddleware(req: Request, res: Response, next: NextFunction): void {
  const incoming = req.header('x-request-id');
  const requestId = incoming && incoming.trim().length > 0 ? incoming : randomUUID();
  (req as RequestWithId).id = requestId;
  res.setHeader('X-Request-Id', requestId);

  const startedAt = Date.now();
  res.on('finish', () => {
    const durationMs = Date.now() - startedAt;
    logger.log(
      `${req.method} ${req.originalUrl} -> ${res.statusCode} (${durationMs}ms) [${requestId}]`,
    );
  });

  next();
}
