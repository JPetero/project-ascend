import { Test } from '@nestjs/testing';
import { HealthMetric } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { HealthMetricsService } from './health-metrics.service';

describe('HealthMetricsService', () => {
  let service: HealthMetricsService;
  let prisma: {
    healthMetricSample: { createMany: jest.Mock; findMany: jest.Mock; count: jest.Mock };
    healthSyncCursor: { upsert: jest.Mock; findMany: jest.Mock; deleteMany: jest.Mock };
  };

  beforeEach(async () => {
    prisma = {
      healthMetricSample: {
        createMany: jest.fn(),
        findMany: jest.fn(),
        count: jest.fn(),
      },
      healthSyncCursor: {
        upsert: jest.fn(),
        findMany: jest.fn(),
        deleteMany: jest.fn(),
      },
    };

    const moduleRef = await Test.createTestingModule({
      providers: [HealthMetricsService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = moduleRef.get(HealthMetricsService);
  });

  const sample = (overrides: Partial<Record<string, unknown>> = {}) => ({
    metric: HealthMetric.STEPS,
    value: 1000,
    unit: 'count',
    recordedAt: '2026-08-06T08:00:00.000Z',
    ...overrides,
  });

  it('returns a no-op result for an empty sync batch', async () => {
    const result = await service.sync('user-1', { provider: 'HEALTH_CONNECT', samples: [] });

    expect(result.data).toEqual({ samplesAdded: 0, samplesSkipped: 0, nextCursor: {} });
    expect(prisma.healthMetricSample.createMany).not.toHaveBeenCalled();
  });

  it('inserts new samples and reports the count added', async () => {
    prisma.healthMetricSample.createMany.mockResolvedValue({ count: 2 });

    const result = await service.sync('user-1', {
      provider: 'HEALTH_CONNECT',
      samples: [sample(), sample({ recordedAt: '2026-08-06T09:00:00.000Z' })],
    });

    expect(result.data.samplesAdded).toBe(2);
    expect(result.data.samplesSkipped).toBe(0);
  });

  it('reports duplicates as skipped, not errored, via skipDuplicates', async () => {
    // 3 submitted, only 1 actually new — createMany's own dedup handled it.
    prisma.healthMetricSample.createMany.mockResolvedValue({ count: 1 });

    const result = await service.sync('user-1', {
      provider: 'HEALTH_CONNECT',
      samples: [sample(), sample(), sample()],
    });

    expect(prisma.healthMetricSample.createMany).toHaveBeenCalledWith(
      expect.objectContaining({ skipDuplicates: true }),
    );
    expect(result.data.samplesAdded).toBe(1);
    expect(result.data.samplesSkipped).toBe(2);
  });

  it('advances the sync cursor to the latest sample per metric, even when duplicates were skipped', async () => {
    prisma.healthMetricSample.createMany.mockResolvedValue({ count: 0 });

    await service.sync('user-1', {
      provider: 'HEALTH_CONNECT',
      samples: [
        sample({ metric: HealthMetric.STEPS, recordedAt: '2026-08-06T08:00:00.000Z' }),
        sample({ metric: HealthMetric.STEPS, recordedAt: '2026-08-06T10:00:00.000Z' }),
        sample({ metric: HealthMetric.HEART_RATE, recordedAt: '2026-08-06T09:00:00.000Z' }),
      ],
    });

    expect(prisma.healthSyncCursor.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          userId_provider_metric: {
            userId: 'user-1',
            provider: 'HEALTH_CONNECT',
            metric: HealthMetric.STEPS,
          },
        },
        create: expect.objectContaining({ cursor: '2026-08-06T10:00:00.000Z' }),
      }),
    );
    expect(prisma.healthSyncCursor.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          userId_provider_metric: {
            userId: 'user-1',
            provider: 'HEALTH_CONNECT',
            metric: HealthMetric.HEART_RATE,
          },
        },
      }),
    );
  });

  it('filters samples by metric and date range', async () => {
    prisma.healthMetricSample.findMany.mockResolvedValue([]);
    prisma.healthMetricSample.count.mockResolvedValue(0);

    await service.listSamples('user-1', {
      metric: HealthMetric.STEPS,
      from: '2026-08-01T00:00:00.000Z',
      to: '2026-08-07T00:00:00.000Z',
      page: 1,
      limit: 50,
    });

    expect(prisma.healthMetricSample.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          userId: 'user-1',
          metric: HealthMetric.STEPS,
          recordedAt: {
            gte: new Date('2026-08-01T00:00:00.000Z'),
            lte: new Date('2026-08-07T00:00:00.000Z'),
          },
        },
      }),
    );
  });

  it('clears only the cursors for the given provider', async () => {
    await service.clearCursorsForProvider('user-1', 'HEALTH_CONNECT');

    expect(prisma.healthSyncCursor.deleteMany).toHaveBeenCalledWith({
      where: { userId: 'user-1', provider: 'HEALTH_CONNECT' },
    });
  });
});
