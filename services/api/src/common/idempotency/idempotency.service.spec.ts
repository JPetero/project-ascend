import { ConflictException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Prisma, SyncOperationStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { IdempotencyService } from './idempotency.service';

function p2002() {
  return new Prisma.PrismaClientKnownRequestError('Unique constraint failed', {
    code: 'P2002',
    clientVersion: 'test',
  });
}

describe('IdempotencyService', () => {
  let service: IdempotencyService;
  let prisma: {
    syncOperation: {
      create: jest.Mock;
      update: jest.Mock;
      findUnique: jest.Mock;
      delete: jest.Mock;
    };
  };

  beforeEach(async () => {
    prisma = {
      syncOperation: {
        create: jest.fn(),
        update: jest.fn(),
        findUnique: jest.fn(),
        delete: jest.fn(),
      },
    };

    const moduleRef = await Test.createTestingModule({
      providers: [IdempotencyService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = moduleRef.get(IdempotencyService);
  });

  const baseParams = {
    userId: 'user-1',
    idempotencyKey: 'key-1',
    entityType: 'MEAL_ENTRY',
    operationType: 'CREATE',
  };

  it('runs fn exactly once for a first-seen key and records the result as COMPLETED', async () => {
    prisma.syncOperation.create.mockResolvedValue({ id: 'op-1' });
    const fn = jest.fn().mockResolvedValue({ entityId: 'entity-1', payload: { ok: true } });

    const result = await service.run(baseParams, fn);

    expect(result).toEqual({ ok: true });
    expect(fn).toHaveBeenCalledTimes(1);
    expect(prisma.syncOperation.update).toHaveBeenCalledWith({
      where: { id: 'op-1' },
      data: {
        status: SyncOperationStatus.COMPLETED,
        resultEntityId: 'entity-1',
        resultPayload: { ok: true },
      },
    });
  });

  it('a repeated request with the same key replays the stored result without re-running fn', async () => {
    prisma.syncOperation.create.mockRejectedValue(p2002());
    prisma.syncOperation.findUnique.mockResolvedValue({
      id: 'op-1',
      status: SyncOperationStatus.COMPLETED,
      resultPayload: { ok: true, id: 'entity-1' },
    });
    const fn = jest.fn();

    const result = await service.run(baseParams, fn);

    expect(result).toEqual({ ok: true, id: 'entity-1' });
    expect(fn).not.toHaveBeenCalled();
  });

  it('rejects a key that is still PROCESSING with a 409 instead of racing it', async () => {
    prisma.syncOperation.create.mockRejectedValue(p2002());
    prisma.syncOperation.findUnique.mockResolvedValue({
      id: 'op-1',
      status: SyncOperationStatus.PROCESSING,
    });
    const fn = jest.fn();

    await expect(service.run(baseParams, fn)).rejects.toBeInstanceOf(ConflictException);
    expect(fn).not.toHaveBeenCalled();
  });

  it('a timeout followed by retry (FAILED status) clears the failed record and runs fn again', async () => {
    prisma.syncOperation.create
      .mockRejectedValueOnce(p2002())
      .mockResolvedValueOnce({ id: 'op-2' });
    prisma.syncOperation.findUnique.mockResolvedValue({
      id: 'op-1',
      status: SyncOperationStatus.FAILED,
    });
    const fn = jest.fn().mockResolvedValue({ entityId: 'entity-1', payload: { ok: true } });

    const result = await service.run(baseParams, fn);

    expect(prisma.syncOperation.delete).toHaveBeenCalledWith({ where: { id: 'op-1' } });
    expect(fn).toHaveBeenCalledTimes(1);
    expect(result).toEqual({ ok: true });
  });

  it('marks the operation FAILED and rethrows when fn itself throws', async () => {
    prisma.syncOperation.create.mockResolvedValue({ id: 'op-1' });
    const error = new Error('downstream failure');
    const fn = jest.fn().mockRejectedValue(error);

    await expect(service.run(baseParams, fn)).rejects.toBe(error);

    expect(prisma.syncOperation.update).toHaveBeenCalledWith({
      where: { id: 'op-1' },
      data: {
        status: SyncOperationStatus.FAILED,
        errorMessage: 'downstream failure',
      },
    });
  });

  it('scopes keys per user, so two users reusing the same key string never collide', async () => {
    // The (userId, idempotencyKey) unique constraint means a second user
    // presenting the same key string is a distinct row, not a conflict —
    // simulated here by both creates succeeding independently.
    prisma.syncOperation.create
      .mockResolvedValueOnce({ id: 'op-user-1' })
      .mockResolvedValueOnce({ id: 'op-user-2' });
    const fnA = jest.fn().mockResolvedValue({ entityId: 'a', payload: { owner: 'user-1' } });
    const fnB = jest.fn().mockResolvedValue({ entityId: 'b', payload: { owner: 'user-2' } });

    const resultA = await service.run({ ...baseParams, userId: 'user-1' }, fnA);
    const resultB = await service.run({ ...baseParams, userId: 'user-2' }, fnB);

    expect(resultA).toEqual({ owner: 'user-1' });
    expect(resultB).toEqual({ owner: 'user-2' });
    expect(fnA).toHaveBeenCalledTimes(1);
    expect(fnB).toHaveBeenCalledTimes(1);
  });

  it('re-runs fn if the colliding row vanished between the failed create and the lookup', async () => {
    prisma.syncOperation.create
      .mockRejectedValueOnce(p2002())
      .mockResolvedValueOnce({ id: 'op-2' });
    prisma.syncOperation.findUnique.mockResolvedValue(null);
    const fn = jest.fn().mockResolvedValue({ entityId: 'entity-1', payload: { ok: true } });

    const result = await service.run(baseParams, fn);

    expect(fn).toHaveBeenCalledTimes(1);
    expect(result).toEqual({ ok: true });
  });
});
