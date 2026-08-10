import { RankingScope } from '@prisma/client';

/**
 * Locality tiers, broadest to narrowest, for the four scopes that
 * resolve against a place rather than a social graph or "everyone"
 * (FRIENDS and GLOBAL need no locality data at all). Index order
 * matters: opting in at a given scope requires every field from
 * localityCountry through that scope's own field, and viewing a
 * broader scope than the one you opted into is allowed as long as you
 * have that scope's required fields. Shared across the Rankings and
 * Sports modules — see resolve-scope-candidates.util.ts, which both
 * RankingsService and SportsService use for identical candidate
 * resolution against the same RankingOptIn data (Build Session 13
 * continuation Part E — Sports Rankings integration).
 */
export const LOCALITY_TIER_ORDER: RankingScope[] = [
  RankingScope.NATIONAL,
  RankingScope.REGION,
  RankingScope.CITY,
  RankingScope.LOCAL,
];

export type LocalityFieldName =
  'localityCountry' | 'localityRegion' | 'localityCity' | 'localityArea';

const LOCALITY_FIELDS_BY_TIER: LocalityFieldName[] = [
  'localityCountry',
  'localityRegion',
  'localityCity',
  'localityArea',
];

/** -1 for FRIENDS/GLOBAL (not a locality scope), else 0-3. */
export function localityTierIndex(scope: RankingScope): number {
  return LOCALITY_TIER_ORDER.indexOf(scope);
}

export function isLocalityScope(scope: RankingScope): boolean {
  return localityTierIndex(scope) >= 0;
}

/** The locality fields required to opt into or view `scope`, broadest first. */
export function requiredLocalityFields(scope: RankingScope): LocalityFieldName[] {
  const tier = localityTierIndex(scope);
  if (tier < 0) return [];
  return LOCALITY_FIELDS_BY_TIER.slice(0, tier + 1);
}
