-- CreateEnum
CREATE TYPE "CommunityPostMediaType" AS ENUM ('TEXT', 'IMAGE', 'VIDEO');

-- CreateEnum
CREATE TYPE "CommunityVisibility" AS ENUM ('PUBLIC', 'FOLLOWERS', 'PRIVATE');

-- CreateEnum
CREATE TYPE "CommunityModerationStatus" AS ENUM ('APPROVED', 'PENDING', 'REMOVED');

-- CreateEnum
CREATE TYPE "CommunityReportTargetType" AS ENUM ('POST', 'COMMENT', 'PROFILE');

-- CreateEnum
CREATE TYPE "CommunityReportStatus" AS ENUM ('OPEN', 'REVIEWED', 'ACTIONED');

-- CreateTable
CREATE TABLE "community_profiles" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "displayName" TEXT NOT NULL,
    "bio" TEXT,
    "avatarUrl" TEXT,
    "isTrainer" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "community_profiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "community_posts" (
    "id" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "mediaType" "CommunityPostMediaType" NOT NULL DEFAULT 'TEXT',
    "mediaUrl" TEXT,
    "caption" TEXT,
    "visibility" "CommunityVisibility" NOT NULL DEFAULT 'PUBLIC',
    "moderationStatus" "CommunityModerationStatus" NOT NULL DEFAULT 'APPROVED',
    "isTrainerContent" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "community_posts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "community_likes" (
    "id" TEXT NOT NULL,
    "postId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "community_likes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "community_comments" (
    "id" TEXT NOT NULL,
    "postId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "community_comments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "community_saves" (
    "id" TEXT NOT NULL,
    "postId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "community_saves_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "community_follows" (
    "id" TEXT NOT NULL,
    "followerId" TEXT NOT NULL,
    "followingId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "community_follows_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "community_blocks" (
    "id" TEXT NOT NULL,
    "blockerId" TEXT NOT NULL,
    "blockedId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "community_blocks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "community_reports" (
    "id" TEXT NOT NULL,
    "reporterId" TEXT NOT NULL,
    "targetType" "CommunityReportTargetType" NOT NULL,
    "targetId" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "status" "CommunityReportStatus" NOT NULL DEFAULT 'OPEN',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "community_reports_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "community_profiles_userId_key" ON "community_profiles"("userId");

-- CreateIndex
CREATE INDEX "community_posts_authorId_createdAt_idx" ON "community_posts"("authorId", "createdAt");

-- CreateIndex
CREATE INDEX "community_posts_visibility_moderationStatus_createdAt_idx" ON "community_posts"("visibility", "moderationStatus", "createdAt");

-- CreateIndex
CREATE INDEX "community_likes_userId_idx" ON "community_likes"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "community_likes_postId_userId_key" ON "community_likes"("postId", "userId");

-- CreateIndex
CREATE INDEX "community_comments_postId_createdAt_idx" ON "community_comments"("postId", "createdAt");

-- CreateIndex
CREATE INDEX "community_saves_userId_idx" ON "community_saves"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "community_saves_postId_userId_key" ON "community_saves"("postId", "userId");

-- CreateIndex
CREATE INDEX "community_follows_followingId_idx" ON "community_follows"("followingId");

-- CreateIndex
CREATE UNIQUE INDEX "community_follows_followerId_followingId_key" ON "community_follows"("followerId", "followingId");

-- CreateIndex
CREATE INDEX "community_blocks_blockedId_idx" ON "community_blocks"("blockedId");

-- CreateIndex
CREATE UNIQUE INDEX "community_blocks_blockerId_blockedId_key" ON "community_blocks"("blockerId", "blockedId");

-- CreateIndex
CREATE INDEX "community_reports_targetType_targetId_idx" ON "community_reports"("targetType", "targetId");

-- CreateIndex
CREATE INDEX "community_reports_status_idx" ON "community_reports"("status");

-- AddForeignKey
ALTER TABLE "community_profiles" ADD CONSTRAINT "community_profiles_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "community_posts" ADD CONSTRAINT "community_posts_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "community_likes" ADD CONSTRAINT "community_likes_postId_fkey" FOREIGN KEY ("postId") REFERENCES "community_posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "community_likes" ADD CONSTRAINT "community_likes_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "community_comments" ADD CONSTRAINT "community_comments_postId_fkey" FOREIGN KEY ("postId") REFERENCES "community_posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "community_comments" ADD CONSTRAINT "community_comments_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "community_saves" ADD CONSTRAINT "community_saves_postId_fkey" FOREIGN KEY ("postId") REFERENCES "community_posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "community_saves" ADD CONSTRAINT "community_saves_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "community_follows" ADD CONSTRAINT "community_follows_followerId_fkey" FOREIGN KEY ("followerId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "community_follows" ADD CONSTRAINT "community_follows_followingId_fkey" FOREIGN KEY ("followingId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "community_blocks" ADD CONSTRAINT "community_blocks_blockerId_fkey" FOREIGN KEY ("blockerId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "community_blocks" ADD CONSTRAINT "community_blocks_blockedId_fkey" FOREIGN KEY ("blockedId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "community_reports" ADD CONSTRAINT "community_reports_reporterId_fkey" FOREIGN KEY ("reporterId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
