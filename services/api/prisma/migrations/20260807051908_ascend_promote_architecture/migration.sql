-- CreateEnum
CREATE TYPE "PromotedCampaignStatus" AS ENUM ('PENDING_REVIEW', 'ACTIVE', 'REJECTED', 'ENDED');

-- CreateTable
CREATE TABLE "promoted_campaigns" (
    "id" TEXT NOT NULL,
    "creatorId" TEXT NOT NULL,
    "postId" TEXT NOT NULL,
    "status" "PromotedCampaignStatus" NOT NULL DEFAULT 'PENDING_REVIEW',
    "budgetAmount" DOUBLE PRECISION NOT NULL,
    "budgetCurrency" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "reviewedAt" TIMESTAMP(3),
    "reviewedBy" TEXT,
    "endedAt" TIMESTAMP(3),

    CONSTRAINT "promoted_campaigns_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "promoted_impressions" (
    "id" TEXT NOT NULL,
    "campaignId" TEXT NOT NULL,
    "viewerId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "promoted_impressions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "promoted_clicks" (
    "id" TEXT NOT NULL,
    "campaignId" TEXT NOT NULL,
    "viewerId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "promoted_clicks_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "promoted_campaigns_status_idx" ON "promoted_campaigns"("status");

-- CreateIndex
CREATE INDEX "promoted_campaigns_creatorId_idx" ON "promoted_campaigns"("creatorId");

-- CreateIndex
CREATE INDEX "promoted_campaigns_postId_idx" ON "promoted_campaigns"("postId");

-- CreateIndex
CREATE INDEX "promoted_impressions_campaignId_idx" ON "promoted_impressions"("campaignId");

-- CreateIndex
CREATE INDEX "promoted_impressions_viewerId_createdAt_idx" ON "promoted_impressions"("viewerId", "createdAt");

-- CreateIndex
CREATE INDEX "promoted_clicks_campaignId_idx" ON "promoted_clicks"("campaignId");

-- AddForeignKey
ALTER TABLE "promoted_campaigns" ADD CONSTRAINT "promoted_campaigns_creatorId_fkey" FOREIGN KEY ("creatorId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "promoted_campaigns" ADD CONSTRAINT "promoted_campaigns_postId_fkey" FOREIGN KEY ("postId") REFERENCES "community_posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "promoted_impressions" ADD CONSTRAINT "promoted_impressions_campaignId_fkey" FOREIGN KEY ("campaignId") REFERENCES "promoted_campaigns"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "promoted_clicks" ADD CONSTRAINT "promoted_clicks_campaignId_fkey" FOREIGN KEY ("campaignId") REFERENCES "promoted_campaigns"("id") ON DELETE CASCADE ON UPDATE CASCADE;
