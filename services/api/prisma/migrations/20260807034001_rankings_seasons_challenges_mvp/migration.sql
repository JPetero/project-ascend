-- CreateEnum
CREATE TYPE "RankingScope" AS ENUM ('FRIENDS', 'REGION', 'GLOBAL');

-- CreateTable
CREATE TABLE "ranking_opt_ins" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "scope" "RankingScope" NOT NULL,
    "regionLabel" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ranking_opt_ins_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ranking_seasons" (
    "id" TEXT NOT NULL,
    "label" TEXT NOT NULL,
    "startsAt" TIMESTAMP(3) NOT NULL,
    "endsAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ranking_seasons_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "challenges" (
    "id" TEXT NOT NULL,
    "creatorId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "startsAt" TIMESTAMP(3) NOT NULL,
    "endsAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "challenges_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "challenge_participants" (
    "id" TEXT NOT NULL,
    "challengeId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "joinedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "challenge_participants_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ranking_opt_ins_userId_key" ON "ranking_opt_ins"("userId");

-- CreateIndex
CREATE INDEX "ranking_seasons_startsAt_endsAt_idx" ON "ranking_seasons"("startsAt", "endsAt");

-- CreateIndex
CREATE INDEX "challenges_creatorId_idx" ON "challenges"("creatorId");

-- CreateIndex
CREATE INDEX "challenges_endsAt_idx" ON "challenges"("endsAt");

-- CreateIndex
CREATE INDEX "challenge_participants_userId_idx" ON "challenge_participants"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "challenge_participants_challengeId_userId_key" ON "challenge_participants"("challengeId", "userId");

-- AddForeignKey
ALTER TABLE "ranking_opt_ins" ADD CONSTRAINT "ranking_opt_ins_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "challenges" ADD CONSTRAINT "challenges_creatorId_fkey" FOREIGN KEY ("creatorId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "challenge_participants" ADD CONSTRAINT "challenge_participants_challengeId_fkey" FOREIGN KEY ("challengeId") REFERENCES "challenges"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "challenge_participants" ADD CONSTRAINT "challenge_participants_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
