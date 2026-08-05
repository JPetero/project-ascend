-- AlterTable: add familyId as nullable first so existing rows don't
-- violate NOT NULL, then backfill and tighten.
ALTER TABLE "refresh_tokens" ADD COLUMN "familyId" TEXT;

-- Backfill: every pre-existing refresh token becomes its own single-token
-- family. We have no historical rotation-chain data to reconstruct real
-- lineages, so treating each as independent is the safe default — it never
-- under-revokes (worst case a legacy token's "family" is just itself).
UPDATE "refresh_tokens" SET "familyId" = "id" WHERE "familyId" IS NULL;

ALTER TABLE "refresh_tokens" ALTER COLUMN "familyId" SET NOT NULL;

-- CreateIndex
CREATE INDEX "refresh_tokens_familyId_idx" ON "refresh_tokens"("familyId");

-- Dedupe device_connections before enforcing (userId, provider) uniqueness:
-- keep the most recently created row per pair, drop the rest.
DELETE FROM "device_connections" dc
USING (
  SELECT "id",
         ROW_NUMBER() OVER (
           PARTITION BY "userId", "provider"
           ORDER BY "createdAt" DESC, "id" DESC
         ) AS rn
  FROM "device_connections"
) ranked
WHERE dc."id" = ranked."id" AND ranked.rn > 1;

-- CreateIndex
CREATE UNIQUE INDEX "device_connections_userId_provider_key" ON "device_connections"("userId", "provider");
