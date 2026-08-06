-- CreateEnum
CREATE TYPE "CoachingStyle" AS ENUM ('GENTLE', 'BALANCED', 'DIRECT', 'TOUGH', 'ATHLETE');

-- CreateEnum
CREATE TYPE "AuthProvider" AS ENUM ('EMAIL', 'GOOGLE', 'APPLE');

-- CreateEnum
CREATE TYPE "LegalDocumentType" AS ENUM ('TERMS_OF_SERVICE', 'PRIVACY_POLICY');

-- AlterTable
ALTER TABLE "preferences" ADD COLUMN     "coachingStyle" "CoachingStyle" NOT NULL DEFAULT 'BALANCED',
ADD COLUMN     "toneIntensity" INTEGER NOT NULL DEFAULT 3;

-- CreateTable
CREATE TABLE "auth_identities" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "provider" "AuthProvider" NOT NULL,
    "providerSubject" TEXT NOT NULL,
    "providerEmail" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastUsedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "auth_identities_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "legal_documents" (
    "id" TEXT NOT NULL,
    "type" "LegalDocumentType" NOT NULL,
    "version" TEXT NOT NULL,
    "publishedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "content" TEXT NOT NULL,

    CONSTRAINT "legal_documents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "legal_acceptances" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "legalDocumentId" TEXT NOT NULL,
    "acceptedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "regionCode" TEXT,

    CONSTRAINT "legal_acceptances_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "deload_recommendations" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "suggestedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reason" TEXT NOT NULL,
    "dismissedAt" TIMESTAMP(3),
    "postponedUntil" TIMESTAMP(3),

    CONSTRAINT "deload_recommendations_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "auth_identities_userId_idx" ON "auth_identities"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "auth_identities_provider_providerSubject_key" ON "auth_identities"("provider", "providerSubject");

-- CreateIndex
CREATE UNIQUE INDEX "legal_documents_type_version_key" ON "legal_documents"("type", "version");

-- CreateIndex
CREATE INDEX "legal_acceptances_userId_idx" ON "legal_acceptances"("userId");

-- CreateIndex
CREATE INDEX "legal_acceptances_legalDocumentId_idx" ON "legal_acceptances"("legalDocumentId");

-- CreateIndex
CREATE INDEX "deload_recommendations_userId_idx" ON "deload_recommendations"("userId");

-- AddForeignKey
ALTER TABLE "auth_identities" ADD CONSTRAINT "auth_identities_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "legal_acceptances" ADD CONSTRAINT "legal_acceptances_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "legal_acceptances" ADD CONSTRAINT "legal_acceptances_legalDocumentId_fkey" FOREIGN KEY ("legalDocumentId") REFERENCES "legal_documents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deload_recommendations" ADD CONSTRAINT "deload_recommendations_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Backfill: every existing user authenticates with email/password today, so
-- give each one an EMAIL AuthIdentity row keyed on their own user id. This
-- keeps the "look up account by identity" path uniform once Google/Apple
-- linking (Scenario 2/3) starts writing GOOGLE/APPLE rows alongside it,
-- without disturbing any existing login behavior.
INSERT INTO "auth_identities" ("id", "userId", "provider", "providerSubject", "providerEmail", "createdAt", "lastUsedAt")
SELECT gen_random_uuid()::text, "id", 'EMAIL', "id", "email", "createdAt", "createdAt"
FROM "users";
