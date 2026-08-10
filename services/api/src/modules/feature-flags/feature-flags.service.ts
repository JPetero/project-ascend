import { Injectable, NotFoundException } from '@nestjs/common';
import { FeatureFlag } from '@prisma/client';
import { createHash } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { UpsertFeatureFlagDto } from './dto/upsert-feature-flag.dto';
import { FEATURE_FLAG_REGISTRY, isRegisteredFeatureKey } from './feature-flag-registry';

export interface FeatureFlagAdminEntry {
  key: string;
  description: string | null;
  enabled: boolean;
  rolloutPercentage: number;
  /** null for an ad-hoc key with no registry entry. */
  defaultEnabled: boolean | null;
  risk: string | null;
  /** Whether an explicit `FeatureFlag` row exists overriding the registry default. */
  hasOverride: boolean;
  id: string | null;
  createdAt: Date | null;
  updatedAt: Date | null;
}

/**
 * Build Session 12 Part 15-17's minimal flag platform, redesigned in
 * Build Session 13 Part 1 around an explicit registry
 * (`feature-flag-registry.ts`) — see that file's doc comment for why.
 */
@Injectable()
export class FeatureFlagsService {
  constructor(private readonly prisma: PrismaService) {}

  async listAll() {
    return this.prisma.featureFlag.findMany({ orderBy: { key: 'asc' } });
  }

  /**
   * Admin-facing listing — every registered key appears even with no
   * override row (so an admin can discover and flip a flag without
   * first guessing its exact key string), annotated with its registry
   * default and risk classification. Ad-hoc keys an admin created
   * outside the registry still appear, with `defaultEnabled`/`risk` null.
   */
  async listAllWithDefinitions(): Promise<FeatureFlagAdminEntry[]> {
    const rows = await this.prisma.featureFlag.findMany({ orderBy: { key: 'asc' } });
    const rowByKey = new Map(rows.map((row) => [row.key, row]));

    const registryEntries: FeatureFlagAdminEntry[] = Object.values(FEATURE_FLAG_REGISTRY).map(
      (definition) => {
        const row = rowByKey.get(definition.key);
        return {
          key: definition.key,
          description: row?.description ?? definition.description,
          enabled: row?.enabled ?? definition.defaultEnabled,
          rolloutPercentage: row?.rolloutPercentage ?? (definition.defaultEnabled ? 100 : 0),
          defaultEnabled: definition.defaultEnabled,
          risk: definition.risk,
          hasOverride: !!row,
          id: row?.id ?? null,
          createdAt: row?.createdAt ?? null,
          updatedAt: row?.updatedAt ?? null,
        };
      },
    );

    const adHocEntries: FeatureFlagAdminEntry[] = rows
      .filter((row) => !isRegisteredFeatureKey(row.key))
      .map((row) => ({
        key: row.key,
        description: row.description,
        enabled: row.enabled,
        rolloutPercentage: row.rolloutPercentage,
        defaultEnabled: null,
        risk: null,
        hasOverride: true,
        id: row.id,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      }));

    return [...registryEntries, ...adHocEntries].sort((a, b) => a.key.localeCompare(b.key));
  }

  async upsert(key: string, dto: UpsertFeatureFlagDto) {
    return this.prisma.featureFlag.upsert({
      where: { key },
      update: dto,
      create: {
        key,
        description: dto.description,
        enabled: dto.enabled ?? false,
        rolloutPercentage: dto.rolloutPercentage ?? 100,
      },
    });
  }

  async delete(key: string) {
    const existing = await this.prisma.featureFlag.findUnique({ where: { key } });
    if (!existing) throw new NotFoundException('Feature flag not found.');
    await this.prisma.featureFlag.delete({ where: { key } });
  }

  /**
   * Resolves every registered flag to a real boolean for one user —
   * always, even with zero `FeatureFlag` rows in the database — plus
   * any ad-hoc (unregistered) flag an admin has created a row for.
   * A registered key is never absent from the result; an ad-hoc key
   * with no row is (nothing to resolve it to — see `upsert`/`delete`,
   * the only way an ad-hoc key gets a value at all).
   */
  async resolveForUser(userId: string): Promise<Record<string, boolean>> {
    const rows = await this.prisma.featureFlag.findMany();
    const rowByKey = new Map(rows.map((row) => [row.key, row]));
    const resolved: Record<string, boolean> = {};

    for (const definition of Object.values(FEATURE_FLAG_REGISTRY)) {
      const row = rowByKey.get(definition.key);
      resolved[definition.key] = row ? this.resolveRow(row, userId) : definition.defaultEnabled;
    }

    for (const row of rows) {
      if (!(row.key in resolved)) {
        resolved[row.key] = this.resolveRow(row, userId);
      }
    }

    return resolved;
  }

  private resolveRow(
    flag: Pick<FeatureFlag, 'key' | 'enabled' | 'rolloutPercentage'>,
    userId: string,
  ): boolean {
    if (!flag.enabled) return false;
    if (flag.rolloutPercentage >= 100) return true;
    if (flag.rolloutPercentage <= 0) return false;
    return this.bucketFor(flag.key, userId) < flag.rolloutPercentage;
  }

  /** Deterministic 0-99 bucket for a (key, userId) pair. */
  private bucketFor(key: string, userId: string): number {
    const digest = createHash('sha256').update(`${key}:${userId}`).digest();
    return digest.readUInt32BE(0) % 100;
  }
}
