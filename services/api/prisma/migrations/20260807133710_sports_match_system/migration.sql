-- CreateEnum
CREATE TYPE "SportCode" AS ENUM ('BADMINTON');

-- CreateEnum
CREATE TYPE "SportMatchStatus" AS ENUM ('CREATED', 'INVITED', 'READY', 'IN_PROGRESS', 'SCORE_PENDING', 'DISPUTED', 'CONFIRMED', 'CANCELED', 'VOID');

-- CreateEnum
CREATE TYPE "SportMatchParticipantStatus" AS ENUM ('INVITED', 'ACCEPTED', 'DECLINED', 'READY', 'LEFT');

-- CreateEnum
CREATE TYPE "SportScoreProposalStatus" AS ENUM ('PENDING', 'CONFIRMED', 'REJECTED', 'SUPERSEDED');

-- CreateTable
CREATE TABLE "sports" (
    "id" TEXT NOT NULL,
    "code" "SportCode" NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "sports_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sport_rule_sets" (
    "id" TEXT NOT NULL,
    "sportId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "pointsToWinSet" INTEGER NOT NULL,
    "setsToWin" INTEGER NOT NULL,

    CONSTRAINT "sport_rule_sets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sport_matches" (
    "id" TEXT NOT NULL,
    "sportId" TEXT NOT NULL,
    "ruleSetId" TEXT,
    "createdById" TEXT NOT NULL,
    "status" "SportMatchStatus" NOT NULL DEFAULT 'CREATED',
    "flagged" BOOLEAN NOT NULL DEFAULT false,
    "flagReason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "startedAt" TIMESTAMP(3),
    "confirmedAt" TIMESTAMP(3),
    "canceledAt" TIMESTAMP(3),
    "voidedAt" TIMESTAMP(3),

    CONSTRAINT "sport_matches_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sport_match_participants" (
    "id" TEXT NOT NULL,
    "matchId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "status" "SportMatchParticipantStatus" NOT NULL DEFAULT 'INVITED',
    "invitedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "respondedAt" TIMESTAMP(3),
    "readyAt" TIMESTAMP(3),

    CONSTRAINT "sport_match_participants_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sport_score_proposals" (
    "id" TEXT NOT NULL,
    "matchId" TEXT NOT NULL,
    "proposedById" TEXT NOT NULL,
    "proposerScore" INTEGER NOT NULL,
    "opponentScore" INTEGER NOT NULL,
    "status" "SportScoreProposalStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sport_score_proposals_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sport_score_confirmations" (
    "id" TEXT NOT NULL,
    "proposalId" TEXT NOT NULL,
    "confirmedById" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sport_score_confirmations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sport_match_disputes" (
    "id" TEXT NOT NULL,
    "matchId" TEXT NOT NULL,
    "raisedById" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resolvedAt" TIMESTAMP(3),

    CONSTRAINT "sport_match_disputes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sport_ratings" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "sportId" TEXT NOT NULL,
    "rating" DOUBLE PRECISION NOT NULL DEFAULT 1500,
    "isProvisional" BOOLEAN NOT NULL DEFAULT true,
    "matchesPlayed" INTEGER NOT NULL DEFAULT 0,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "sport_ratings_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "sports_code_key" ON "sports"("code");

-- CreateIndex
CREATE INDEX "sport_rule_sets_sportId_idx" ON "sport_rule_sets"("sportId");

-- CreateIndex
CREATE INDEX "sport_matches_createdById_idx" ON "sport_matches"("createdById");

-- CreateIndex
CREATE INDEX "sport_matches_sportId_status_idx" ON "sport_matches"("sportId", "status");

-- CreateIndex
CREATE INDEX "sport_match_participants_userId_status_idx" ON "sport_match_participants"("userId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "sport_match_participants_matchId_userId_key" ON "sport_match_participants"("matchId", "userId");

-- CreateIndex
CREATE INDEX "sport_score_proposals_matchId_status_idx" ON "sport_score_proposals"("matchId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "sport_score_confirmations_proposalId_key" ON "sport_score_confirmations"("proposalId");

-- CreateIndex
CREATE INDEX "sport_match_disputes_matchId_idx" ON "sport_match_disputes"("matchId");

-- CreateIndex
CREATE INDEX "sport_ratings_sportId_rating_idx" ON "sport_ratings"("sportId", "rating");

-- CreateIndex
CREATE UNIQUE INDEX "sport_ratings_userId_sportId_key" ON "sport_ratings"("userId", "sportId");

-- AddForeignKey
ALTER TABLE "sport_rule_sets" ADD CONSTRAINT "sport_rule_sets_sportId_fkey" FOREIGN KEY ("sportId") REFERENCES "sports"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sport_matches" ADD CONSTRAINT "sport_matches_sportId_fkey" FOREIGN KEY ("sportId") REFERENCES "sports"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sport_matches" ADD CONSTRAINT "sport_matches_ruleSetId_fkey" FOREIGN KEY ("ruleSetId") REFERENCES "sport_rule_sets"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sport_matches" ADD CONSTRAINT "sport_matches_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sport_match_participants" ADD CONSTRAINT "sport_match_participants_matchId_fkey" FOREIGN KEY ("matchId") REFERENCES "sport_matches"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sport_match_participants" ADD CONSTRAINT "sport_match_participants_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sport_score_proposals" ADD CONSTRAINT "sport_score_proposals_matchId_fkey" FOREIGN KEY ("matchId") REFERENCES "sport_matches"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sport_score_proposals" ADD CONSTRAINT "sport_score_proposals_proposedById_fkey" FOREIGN KEY ("proposedById") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sport_score_confirmations" ADD CONSTRAINT "sport_score_confirmations_proposalId_fkey" FOREIGN KEY ("proposalId") REFERENCES "sport_score_proposals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sport_score_confirmations" ADD CONSTRAINT "sport_score_confirmations_confirmedById_fkey" FOREIGN KEY ("confirmedById") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sport_match_disputes" ADD CONSTRAINT "sport_match_disputes_matchId_fkey" FOREIGN KEY ("matchId") REFERENCES "sport_matches"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sport_match_disputes" ADD CONSTRAINT "sport_match_disputes_raisedById_fkey" FOREIGN KEY ("raisedById") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sport_ratings" ADD CONSTRAINT "sport_ratings_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sport_ratings" ADD CONSTRAINT "sport_ratings_sportId_fkey" FOREIGN KEY ("sportId") REFERENCES "sports"("id") ON DELETE CASCADE ON UPDATE CASCADE;
