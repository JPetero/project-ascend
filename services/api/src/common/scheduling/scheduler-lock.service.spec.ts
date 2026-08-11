import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { SchedulerLockService } from './scheduler-lock.service';

describe('SchedulerLockService', () => {
  let service: SchedulerLockService;
  let prisma: {
    $executeRaw: jest.Mock;
    scheduledJobLock: { updateMany: jest.Mock };
  };

  beforeEach(async () => {
    prisma = {
      $executeRaw: jest.fn().mockResolvedValue(1),
      scheduledJobLock: { updateMany: jest.fn().mockResolvedValue({ count: 1 }) },
    };

    const moduleRef = await Test.createTestingModule({
      providers: [SchedulerLockService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = moduleRef.get(SchedulerLockService);
  });

  it('runs the job and reports ran: true when the lock is acquired', async () => {
    const job = jest.fn().mockResolvedValue('done');

    const outcome = await service.runExclusive('some-job', job);

    expect(job).toHaveBeenCalled();
    expect(outcome).toEqual({ ran: true, result: 'done' });
  });

  it('does not run the job and reports ran: false when the lock cannot be acquired', async () => {
    prisma.$executeRaw.mockResolvedValue(0);
    const job = jest.fn();

    const outcome = await service.runExclusive('some-job', job);

    expect(job).not.toHaveBeenCalled();
    expect(outcome).toEqual({ ran: false });
    expect(prisma.scheduledJobLock.updateMany).not.toHaveBeenCalled();
  });

  it('releases the lock scoped to this instance after a successful run', async () => {
    await service.runExclusive('some-job', async () => undefined);

    expect(prisma.scheduledJobLock.updateMany).toHaveBeenCalledWith({
      where: { jobName: 'some-job', lockedBy: expect.any(String) },
      data: { lockedUntil: new Date(0) },
    });
  });

  it('releases the lock even when the job throws', async () => {
    const job = jest.fn().mockRejectedValue(new Error('boom'));

    await expect(service.runExclusive('some-job', job)).rejects.toThrow('boom');

    expect(prisma.scheduledJobLock.updateMany).toHaveBeenCalled();
  });

  it('claims the lock via an INSERT ... ON CONFLICT ... WHERE targeting the job-lock row', async () => {
    await service.runExclusive('some-job', async () => undefined);

    const [stringsArray] = prisma.$executeRaw.mock.calls[0] as [readonly string[]];
    const sql = stringsArray.join('?');
    expect(sql).toContain('scheduled_job_locks');
    expect(sql).toContain('ON CONFLICT');
    expect(sql).toContain('WHERE');
  });

  it('runs the job on only one of two concurrent attempts for the same job name', async () => {
    prisma.$executeRaw.mockResolvedValueOnce(1).mockResolvedValueOnce(0);
    const jobA = jest.fn().mockResolvedValue('a');
    const jobB = jest.fn().mockResolvedValue('b');

    const [outcomeA, outcomeB] = await Promise.all([
      service.runExclusive('shared-job', jobA),
      service.runExclusive('shared-job', jobB),
    ]);

    const ranOutcomes = [outcomeA, outcomeB].filter((o) => o.ran);
    expect(ranOutcomes).toHaveLength(1);
  });
});
