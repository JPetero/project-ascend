-- Expand RankingScope with the locality tiers Scenario 16a always
-- specified but the MVP folded into a single REGION scope: LOCAL (a
-- neighborhood/district), CITY, and NATIONAL. FRIENDS/REGION/GLOBAL
-- are unchanged.
ALTER TYPE "RankingScope" ADD VALUE 'LOCAL';
ALTER TYPE "RankingScope" ADD VALUE 'CITY';
ALTER TYPE "RankingScope" ADD VALUE 'NATIONAL';

-- The old free-text regionLabel becomes the region/state tier of a
-- structured hierarchy; existing data is preserved by the rename.
ALTER TABLE "ranking_opt_ins" RENAME COLUMN "regionLabel" TO "localityRegion";
ALTER TABLE "ranking_opt_ins" ADD COLUMN "localityCountry" TEXT;
ALTER TABLE "ranking_opt_ins" ADD COLUMN "localityCity" TEXT;
ALTER TABLE "ranking_opt_ins" ADD COLUMN "localityArea" TEXT;

-- Replace the scope+regionLabel index with one covering the full
-- hierarchy in tier order, so a leaderboard load at any tier can use
-- it as a prefix scan (see RankingsService.resolveScopeCandidates).
DROP INDEX "ranking_opt_ins_scope_regionLabel_idx";
CREATE INDEX "ranking_opt_ins_locality_idx" ON "ranking_opt_ins"("scope", "localityCountry", "localityRegion", "localityCity", "localityArea");
