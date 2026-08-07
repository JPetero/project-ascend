import { Injectable } from '@nestjs/common';
import { HealthMetric } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { QueryHealthSamplesDto } from './dto/query-health-samples.dto';
import { SyncHealthSamplesDto } from './dto/sync-health-samples.dto';

/**
 * Ingests normalized health samples from a connected platform (Android
 * Health Connect, Apple HealthKit, or a vendor surfaced through one of
 * those hubs) — see packages/docs/wearables.md's "Planned architecture
 * for real integrations" section, now implemented. The client-side
 * adapter (apps/mobile/lib/features/wearables/data/health_adapter.dart)
 * does the actual platform read and unit/timezone normalization; this
 * service's job is duplicate-safe storage and incremental-sync
 * bookkeeping, not talking to any platform SDK itself.
 */
@Injectable()
export class HealthMetricsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Duplicate detection relies on the `@@unique([userId, metric,
   * sourceProvider, recordedAt])` constraint — `skipDuplicates` turns a
   * re-sync of already-stored samples (the client's own retry, or an
   * overlapping incremental-sync window) into a safe no-op per row
   * instead of an error or a duplicate row.
   */
  async sync(userId: string, dto: SyncHealthSamplesDto) {
    const { provider, samples } = dto;

    if (samples.length === 0) {
      return { data: { samplesAdded: 0, samplesSkipped: 0, nextCursor: {} }, error: null };
    }

    const result = await this.prisma.healthMetricSample.createMany({
      data: samples.map((sample) => ({
        userId,
        metric: sample.metric,
        value: sample.value,
        unit: sample.unit,
        recordedAt: new Date(sample.recordedAt),
        recordedTimezone: sample.recordedTimezone,
        sourceProvider: provider,
        sourceDeviceId: sample.sourceDeviceId,
        externalId: sample.externalId,
      })),
      skipDuplicates: true,
    });

    const samplesAdded = result.count;
    const samplesSkipped = samples.length - samplesAdded;

    // The cursor advances to the latest sample *considered* in this
    // batch, added or skipped — a duplicate is still evidence the
    // client has already synced up to that point.
    const latestByMetric = new Map<HealthMetric, Date>();
    for (const sample of samples) {
      const recordedAt = new Date(sample.recordedAt);
      const current = latestByMetric.get(sample.metric);
      if (!current || recordedAt > current) {
        latestByMetric.set(sample.metric, recordedAt);
      }
    }

    const nextCursor: Record<string, string> = {};
    for (const [metric, recordedAt] of latestByMetric) {
      const cursor = recordedAt.toISOString();
      await this.prisma.healthSyncCursor.upsert({
        where: { userId_provider_metric: { userId, provider, metric } },
        create: { userId, provider, metric, cursor, lastSyncedAt: new Date() },
        update: { cursor, lastSyncedAt: new Date() },
      });
      nextCursor[metric] = cursor;
    }

    return { data: { samplesAdded, samplesSkipped, nextCursor }, error: null };
  }

  async listSamples(userId: string, query: QueryHealthSamplesDto) {
    const where = {
      userId,
      ...(query.metric ? { metric: query.metric } : {}),
      ...(query.from || query.to
        ? {
            recordedAt: {
              ...(query.from ? { gte: new Date(query.from) } : {}),
              ...(query.to ? { lte: new Date(query.to) } : {}),
            },
          }
        : {}),
    };

    const [samples, total] = await Promise.all([
      this.prisma.healthMetricSample.findMany({
        where,
        orderBy: { recordedAt: 'desc' },
        skip: (query.page - 1) * query.limit,
        take: query.limit,
      }),
      this.prisma.healthMetricSample.count({ where }),
    ]);

    return { data: samples, meta: { page: query.page, limit: query.limit, total } };
  }

  /** Powers the Connected Health screen's per-provider "last sync" and
   * per-metric sync state — see packages/docs/wearables.md. */
  async syncStatus(userId: string) {
    const cursors = await this.prisma.healthSyncCursor.findMany({
      where: { userId },
      orderBy: [{ provider: 'asc' }, { metric: 'asc' }],
    });
    return { data: cursors };
  }

  /** Called by DevicesService.remove() when a device connection is
   * revoked — see that method's own comment for why this lives there
   * rather than requiring the caller to know to call both. */
  async clearCursorsForProvider(userId: string, provider: string): Promise<void> {
    await this.prisma.healthSyncCursor.deleteMany({ where: { userId, provider } });
  }
}
