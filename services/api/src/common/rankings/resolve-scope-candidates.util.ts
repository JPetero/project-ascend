import { BadRequestException } from '@nestjs/common';
import { RankingScope } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { LocalityFieldName, localityTierIndex, requiredLocalityFields } from './locality.util';

type OptInLocalityRow = {
  scope: RankingScope;
  localityCountry: string | null;
  localityRegion: string | null;
  localityCity: string | null;
  localityArea: string | null;
};

/**
 * Everyone the viewer follows (per Community's follow graph) plus the
 * viewer themselves — the FRIENDS candidate set shared by Rankings and
 * Sports leaderboards. Callers still filter this against their own
 * "has opted in" / "has a rating" condition.
 */
export async function resolveFriendsCandidateIds(
  prisma: PrismaService,
  viewerId: string,
): Promise<string[]> {
  const following = await prisma.communityFollow.findMany({
    where: { followerId: viewerId },
    select: { followingId: true },
  });
  return [...following.map((f) => f.followingId), viewerId];
}

/**
 * Every user whose RankingOptIn locality (country/region/city/area,
 * matched case-insensitively) matches the viewer's own, at the given
 * NATIONAL/REGION/CITY/LOCAL tier. Requires the viewer to have opted
 * into Rankings at that tier or narrower — Sports has no locality data
 * of its own, so a sport's regional leaderboard reuses Rankings'
 * opt-in instead of inventing a second per-sport locality opt-in.
 */
export async function resolveLocalityCandidateIds(
  prisma: PrismaService,
  viewerId: string,
  scope: RankingScope,
): Promise<string[]> {
  const viewerOptIn: OptInLocalityRow | null = await prisma.rankingOptIn.findUnique({
    where: { userId: viewerId },
  });
  if (!viewerOptIn || localityTierIndex(viewerOptIn.scope) < localityTierIndex(scope)) {
    throw new BadRequestException(
      `Opt in to Rankings with a ${scope.toLowerCase()} locality (or narrower) to view this leaderboard.`,
    );
  }

  const localityWhere: Record<string, { equals: string; mode: 'insensitive' }> = {};
  for (const field of requiredLocalityFields(scope)) {
    localityWhere[field as LocalityFieldName] = {
      equals: viewerOptIn[field as LocalityFieldName] as string,
      mode: 'insensitive',
    };
  }
  const optedIn = await prisma.rankingOptIn.findMany({
    where: { scope, ...localityWhere },
    select: { userId: true },
  });
  return optedIn.map((o) => o.userId);
}
