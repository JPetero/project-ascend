import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { ResponseEnvelope } from '../dto/response-envelope';

/**
 * Wraps every successful controller response in the shared
 * { data, meta, error } envelope used across the API.
 */
@Injectable()
export class ResponseEnvelopeInterceptor<T> implements NestInterceptor<T, ResponseEnvelope<T>> {
  intercept(_context: ExecutionContext, next: CallHandler<T>): Observable<ResponseEnvelope<T>> {
    return next.handle().pipe(
      map((payload) => {
        if (payload && typeof payload === 'object' && 'data' in payload && 'error' in payload) {
          return payload as unknown as ResponseEnvelope<T>;
        }

        return {
          data: payload ?? null,
          meta: {},
          error: null,
        };
      }),
    );
  }
}
