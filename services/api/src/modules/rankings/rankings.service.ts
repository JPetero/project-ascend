import { ForbiddenException, Injectable } from '@nestjs/common';
import { RankingScope } from '@prisma/client';
import {
  LocalityFieldName,
  isLocalityScope,
  requiredLocalityFields,
} from '../../common/rankings/locality.util';
import {
  resolveFriendsCandidateIds,
  resolveLocalityCandidateIds,
} from '../../common/rankings/resolve-scope-candidates.util';
import {
  computeActivitySummaries,
  computeActivitySummary,
} from '../../common/scoring/activity-scoring.util';
import { PrismaService } from '../../prisma/prisma.service';
import { OptInRankingsDto } from './dto/opt-in-rankings.dto';

type OptInRow = {
  userId: string;
  scope: RankingScope;
  localityCountry: string | null;
  localityRegion: string | null;
  localityCity: string | null;
  localityArea: string | null;
};

/**
 * Rankings — Founder Scenario 16a. Opt-in and off by default (no
 * `RankingOptIn` row = private, never appears anywhere); scores never
 * reward raw volume or an uninterrupted streak alone (see
 * common/scoring/activity-scoring.util.ts); no exact location is ever
 * stored or returned, only user-typed coarse locality labels.
 */
@Injectable()
export class RankingsService {
  constructor(private readonly prisma: PrismaService) {}

  async optIn(userId: string, dto: OptInRankingsDto) {
    // Only the fields the chosen scope's tier actually needs are kept —
    // switching from e.g. LOCAL back to GLOBAL clears the old locality
    // data rather than leaving it stale and unused.
    const required = new Set(requiredLocalityFields(dto.scope));
    const locality: Record<LocalityFieldName, string | null> = {
      localityCountry: required.has('localityCountry') ? (dto.localityCountry ?? null) : null,
      localityRegion: required.has('localityRegion') ? (dto.localityRegion ?? null) : null,
      localityCity: required.has('localityCity') ? (dto.localityCity ?? null) : null,
      localityArea: required.has('localityArea') ? (dto.localityArea ?? null) : null,
    };

    const optIn = await this.prisma.rankingOptIn.upsert({
      where: { userId },
      update: { scope: dto.scope, ...locality },
      create: { userId, scope: dto.scope, ...locality },
    });
    return this.serializeOptIn(optIn);
  }

  async optOut(userId: string): Promise<void> {
    await this.prisma.rankingOptIn.deleteMany({ where: { userId } });
  }

  async getMyStatus(userId: string) {
    const optIn = await this.prisma.rankingOptIn.findUnique({ where: { userId } });
    if (!optIn) return { optedIn: false };

    const season = await this.getOrCreateCurrentSeason();
    const summary = await computeActivitySummary(
      this.prisma,
      userId,
      season.startsAt,
      season.endsAt,
    );
    return {
      optedIn: true,
      scope: optIn.scope,
      localityCountry: optIn.localityCountry,
      localityRegion: optIn.localityRegion,
      localityCity: optIn.localityCity,
      localityArea: optIn.localityArea,
      season: this.serializeSeason(season),
      points: summary.points,
      activeDays: summary.activeDays,
    };
  }

  async getLeaderboard(viewerId: string, scope: RankingScope, page: number, limit: number) {
    const viewerOptIn = await this.prisma.rankingOptIn.findUnique({ where: { userId: viewerId } });
    if (!viewerOptIn) {
      throw new ForbiddenException('Opt in to Rankings to view a leaderboard.');
    }

    const candidateIds = await this.resolveScopeCandidates(viewerId, scope);
    const season = await this.getOrCreateCurrentSeason();

    // Batched — was Promise.all(candidateIds.map(computeActivitySummary)),
    // 3 queries per candidate regardless of which page was requested.
    const summaryByUser = await computeActivitySummaries(
      this.prisma,
      candidateIds,
      season.startsAt,
      season.endsAt,
    );
    const scored = candidateIds.map((userId) => ({
      userId,
      ...(summaryByUser.get(userId) ?? { activeDays: 0, points: 0 }),
    }));

    scored.sort(
      (a, b) =>
        b.points - a.points || b.activeDays - a.activeDays || a.userId.localeCompare(b.userId),
    );

    const userIds = scored.map((s) => s.userId);
    const profiles = await this.prisma.communityProfile.findMany({
      where: { userId: { in: userIds } },
      select: { userId: true, displayName: true, avatarUrl: true },
    });
    const profileByUser = new Map(profiles.map((p) => [p.userId, p]));

    const start = (page - 1) * limit;
    const page_ = scored.slice(start, start + limit).map((entry, index) => ({
      rank: start + index + 1,
      userId: entry.userId,
      displayName: profileByUser.get(entry.userId)?.displayName ?? null,
      avatarUrl: profileByUser.get(entry.userId)?.avatarUrl ?? null,
      points: entry.points,
      activeDays: entry.activeDays,
      isViewer: entry.userId === viewerId,
    }));

    return {
      data: page_,
      meta: { page, limit, total: scored.length, season: this.serializeSeason(season), scope },
    };
  }

  private async resolveScopeCandidates(viewerId: string, scope: RankingScope): Promise<string[]> {
    if (scope === RankingScope.GLOBAL) {
      const optedIn = await this.prisma.rankingOptIn.findMany({
        where: { scope: RankingScope.GLOBAL },
        select: { userId: true },
      });
      return optedIn.map((o) => o.userId);
    }

    if (isLocalityScope(scope)) {
      // Viewing NATIONAL/REGION/CITY/LOCAL requires having opted in at
      // that tier or narrower — a LOCAL opt-in has every field a
      // broader tier needs too, so it can also browse e.g. the CITY or
      // NATIONAL board for the same place. Matching is case-insensitive
      // so "Quezon City" and "Quezon city" land on the same board.
      return resolveLocalityCandidateIds(this.prisma, viewerId, scope);
    }

    // FRIENDS — everyone the viewer follows (per Community's follow
    // graph) who has also opted in to Rankings in any scope, plus the
    // viewer themselves.
    const candidateIds = await resolveFriendsCandidateIds(this.prisma, viewerId);
    const optedIn = await this.prisma.rankingOptIn.findMany({
      where: { userId: { in: candidateIds } },
      select: { userId: true },
    });
    return optedIn.map((o) => o.userId);
  }

  private async getOrCreateCurrentSeason() {
    const now = new Date();
    const existing = await this.prisma.rankingSeason.findFirst({
      where: { startsAt: { lte: now }, endsAt: { gte: now } },
      orderBy: { startsAt: 'desc' },
    });
    if (existing) return existing;

    const startsAt = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
    const endsAt = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1));
    return this.prisma.rankingSeason.create({
      data: {
        label: startsAt.toLocaleString('en-US', {
          month: 'long',
          year: 'numeric',
          timeZone: 'UTC',
        }),
        startsAt,
        endsAt,
      },
    });
  }

  private serializeOptIn(optIn: OptInRow) {
    return {
      userId: optIn.userId,
      scope: optIn.scope,
      localityCountry: optIn.localityCountry,
      localityRegion: optIn.localityRegion,
      localityCity: optIn.localityCity,
      localityArea: optIn.localityArea,
    };
  }

  private serializeSeason(season: { id: string; label: string; startsAt: Date; endsAt: Date }) {
    return { id: season.id, label: season.label, startsAt: season.startsAt, endsAt: season.endsAt };
  }
}
