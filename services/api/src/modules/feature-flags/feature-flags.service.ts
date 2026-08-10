import { Injectable, NotFoundException } from '@nestjs/common';
import { createHash } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { UpsertFeatureFlagDto } from './dto/upsert-feature-flag.dto';

/**
 * Build Session 12 Part 15-17 — minimal feature flag platform. Resolution
 * is deterministic per (key, userId) pair via `bucketFor`, so a given user
 * always lands on the same side of a partial rollout instead of flapping
 * between requests. See FeatureFlag's schema doc comment for the
 * fail-open contract clients are expected to honor for absent keys.
 */
@Injectable()
export class FeatureFlagsService {
  constructor(private readonly prisma: PrismaService) {}

  async listAll() {
    return this.prisma.featureFlag.findMany({ orderBy: { key: 'asc' } });
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
   * Resolves every stored flag to a boolean for one user. A key with no
   * FeatureFlag row at all is simply absent from the returned map —
   * callers (mobile, this same service's other callers) are expected to
   * treat an absent key as enabled (fail-open), never as disabled.
   */
  async resolveForUser(userId: string): Promise<Record<string, boolean>> {
    const flags = await this.prisma.featureFlag.findMany();
    const resolved: Record<string, boolean> = {};
    for (const flag of flags) {
      if (!flag.enabled) {
        resolved[flag.key] = false;
      } else if (flag.rolloutPercentage >= 100) {
        resolved[flag.key] = true;
      } else if (flag.rolloutPercentage <= 0) {
        resolved[flag.key] = false;
      } else {
        resolved[flag.key] = this.bucketFor(flag.key, userId) < flag.rolloutPercentage;
      }
    }
    return resolved;
  }

  /** Deterministic 0-99 bucket for a (key, userId) pair. */
  private bucketFor(key: string, userId: string): number {
    const digest = createHash('sha256').update(`${key}:${userId}`).digest();
    return digest.readUInt32BE(0) % 100;
  }
}
