import { ConflictException, Injectable } from '@nestjs/common';
import { Prisma, SyncOperationStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

export interface IdempotentRunParams {
  userId: string;
  idempotencyKey: string;
  entityType: string;
  operationType: string;
  localEntityId?: string;
  clientCreatedAt?: Date;
}

export interface IdempotentResult<T> {
  entityId?: string;
  payload: T;
}

/**
 * Shared "run this mutation at most once" ledger for every offline-capable
 * write in the app — workout sessions/sets/plans/substitutions today,
 * nutrition entries as of this same session (see
 * packages/docs/build-session-2.md for the conflict policy this
 * implements). A client generates one `idempotencyKey` per logical
 * mutation (typically stored alongside the local/offline record) and
 * resends the same key on every retry of that same mutation.
 *
 * Conflict policy:
 * - A first-seen key runs `fn()` and stores its result; a later retry with
 *   the same key never re-runs `fn()` — it replays the stored result.
 * - A key that's still `PROCESSING` (a genuinely concurrent second request,
 *   or a crashed first attempt that never reached COMPLETED/FAILED) is
 *   rejected with 409 rather than guessed at — the client should retry
 *   shortly rather than the server racing its own in-flight attempt.
 * - A key whose prior attempt `FAILED` is allowed to retry cleanly (the
 *   failed row is replaced, not replayed forever as a failure).
 * - Keys are scoped per user (`@@unique([userId, idempotencyKey])`), so one
 *   user can never observe or replay another user's result even if they
 *   reuse the same key string.
 */
@Injectable()
export class IdempotencyService {
  constructor(private readonly prisma: PrismaService) {}

  async run<T>(params: IdempotentRunParams, fn: () => Promise<IdempotentResult<T>>): Promise<T> {
    let operationId: string;
    try {
      const created = await this.prisma.syncOperation.create({
        data: {
          userId: params.userId,
          idempotencyKey: params.idempotencyKey,
          entityType: params.entityType,
          operationType: params.operationType,
          localEntityId: params.localEntityId,
          clientCreatedAt: params.clientCreatedAt,
          status: SyncOperationStatus.PROCESSING,
        },
      });
      operationId = created.id;
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        return this.replayOrRetry(params, fn);
      }
      throw error;
    }

    try {
      const { entityId, payload } = await fn();
      await this.prisma.syncOperation.update({
        where: { id: operationId },
        data: {
          status: SyncOperationStatus.COMPLETED,
          resultEntityId: entityId,
          resultPayload: payload as unknown as Prisma.InputJsonValue,
        },
      });
      return payload;
    } catch (error) {
      await this.prisma.syncOperation.update({
        where: { id: operationId },
        data: {
          status: SyncOperationStatus.FAILED,
          errorMessage: error instanceof Error ? error.message : 'Unknown error',
        },
      });
      throw error;
    }
  }

  private async replayOrRetry<T>(
    params: IdempotentRunParams,
    fn: () => Promise<IdempotentResult<T>>,
  ): Promise<T> {
    const existing = await this.prisma.syncOperation.findUnique({
      where: {
        userId_idempotencyKey: { userId: params.userId, idempotencyKey: params.idempotencyKey },
      },
    });

    // Vanishingly unlikely (the row this insert collided with would have to
    // be deleted between the failed create and this read) but handled
    // rather than crashing on a null dereference.
    if (!existing) {
      return this.run(params, fn);
    }

    if (existing.status === SyncOperationStatus.COMPLETED) {
      return existing.resultPayload as T;
    }

    if (existing.status === SyncOperationStatus.PROCESSING) {
      throw new ConflictException(
        'This operation is already being processed. Please try again shortly.',
      );
    }

    // FAILED — clear it and let this attempt run fresh.
    await this.prisma.syncOperation.delete({ where: { id: existing.id } });
    return this.run(params, fn);
  }
}
