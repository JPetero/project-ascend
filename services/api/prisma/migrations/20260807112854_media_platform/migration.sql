-- CreateEnum
CREATE TYPE "MediaType" AS ENUM ('PROFILE_IMAGE', 'COVER_IMAGE', 'COMMUNITY_IMAGE', 'COMMUNITY_REEL', 'CHAT_IMAGE', 'MEAL_PHOTO', 'PROGRESS_PHOTO', 'VISION_CAPTURE', 'WORKOUT_SHARE_MEDIA');

-- CreateEnum
CREATE TYPE "MediaVisibility" AS ENUM ('PRIVATE', 'UNLISTED', 'PUBLIC');

-- CreateEnum
CREATE TYPE "MediaProcessingState" AS ENUM ('PENDING', 'PROCESSING', 'READY', 'FAILED');

-- CreateEnum
CREATE TYPE "MediaModerationState" AS ENUM ('PENDING', 'APPROVED', 'FLAGGED', 'REJECTED', 'REMOVED');

-- CreateEnum
CREATE TYPE "MediaRetentionState" AS ENUM ('ACTIVE', 'ARCHIVED', 'PENDING_DELETION', 'DELETED');

-- CreateEnum
CREATE TYPE "MediaUploadState" AS ENUM ('INITIATED', 'COMPLETED', 'FAILED', 'EXPIRED');

-- CreateEnum
CREATE TYPE "MediaVariantType" AS ENUM ('ORIGINAL', 'THUMBNAIL', 'PREVIEW');

-- CreateEnum
CREATE TYPE "MediaUsageType" AS ENUM ('PROFILE_AVATAR', 'PROFILE_COVER', 'COMMUNITY_POST', 'CHAT_MESSAGE', 'MEAL_ENTRY', 'PROGRESS_LOG', 'GALLERY', 'VISION_CAPTURE', 'SPORT_MATCH', 'WORKOUT_SHARE');

-- AlterEnum
ALTER TYPE "CommunityReportTargetType" ADD VALUE 'MEDIA_ASSET';

-- CreateTable
CREATE TABLE "media_assets" (
    "id" TEXT NOT NULL,
    "ownerId" TEXT NOT NULL,
    "mediaType" "MediaType" NOT NULL,
    "originalFilename" TEXT NOT NULL,
    "mimeType" TEXT NOT NULL,
    "sizeBytes" INTEGER NOT NULL,
    "width" INTEGER,
    "height" INTEGER,
    "durationSeconds" DOUBLE PRECISION,
    "storageKey" TEXT NOT NULL,
    "visibility" "MediaVisibility" NOT NULL DEFAULT 'PRIVATE',
    "processingState" "MediaProcessingState" NOT NULL DEFAULT 'PENDING',
    "moderationState" "MediaModerationState" NOT NULL DEFAULT 'PENDING',
    "thumbnailStorageKey" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deletedAt" TIMESTAMP(3),
    "retentionState" "MediaRetentionState" NOT NULL DEFAULT 'ACTIVE',

    CONSTRAINT "media_assets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "media_uploads" (
    "id" TEXT NOT NULL,
    "mediaAssetId" TEXT NOT NULL,
    "state" "MediaUploadState" NOT NULL DEFAULT 'INITIATED',
    "storageProvider" TEXT NOT NULL,
    "uploadMethod" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "media_uploads_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "media_variants" (
    "id" TEXT NOT NULL,
    "mediaAssetId" TEXT NOT NULL,
    "variantType" "MediaVariantType" NOT NULL,
    "storageKey" TEXT NOT NULL,
    "width" INTEGER,
    "height" INTEGER,
    "sizeBytes" INTEGER,
    "mimeType" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "media_variants_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "media_usages" (
    "id" TEXT NOT NULL,
    "mediaAssetId" TEXT NOT NULL,
    "usageType" "MediaUsageType" NOT NULL,
    "referenceId" TEXT NOT NULL,
    "attachedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "media_usages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "media_moderation_results" (
    "id" TEXT NOT NULL,
    "mediaAssetId" TEXT NOT NULL,
    "status" "MediaModerationState" NOT NULL,
    "reasonCode" TEXT,
    "reviewedBy" TEXT,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "media_moderation_results_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "media_assets_storageKey_key" ON "media_assets"("storageKey");

-- CreateIndex
CREATE INDEX "media_assets_ownerId_createdAt_idx" ON "media_assets"("ownerId", "createdAt");

-- CreateIndex
CREATE INDEX "media_assets_moderationState_idx" ON "media_assets"("moderationState");

-- CreateIndex
CREATE INDEX "media_assets_mediaType_ownerId_idx" ON "media_assets"("mediaType", "ownerId");

-- CreateIndex
CREATE UNIQUE INDEX "media_uploads_mediaAssetId_key" ON "media_uploads"("mediaAssetId");

-- CreateIndex
CREATE UNIQUE INDEX "media_variants_mediaAssetId_variantType_key" ON "media_variants"("mediaAssetId", "variantType");

-- CreateIndex
CREATE INDEX "media_usages_mediaAssetId_idx" ON "media_usages"("mediaAssetId");

-- CreateIndex
CREATE INDEX "media_usages_usageType_referenceId_idx" ON "media_usages"("usageType", "referenceId");

-- CreateIndex
CREATE INDEX "media_moderation_results_mediaAssetId_createdAt_idx" ON "media_moderation_results"("mediaAssetId", "createdAt");

-- AddForeignKey
ALTER TABLE "media_assets" ADD CONSTRAINT "media_assets_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "media_uploads" ADD CONSTRAINT "media_uploads_mediaAssetId_fkey" FOREIGN KEY ("mediaAssetId") REFERENCES "media_assets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "media_variants" ADD CONSTRAINT "media_variants_mediaAssetId_fkey" FOREIGN KEY ("mediaAssetId") REFERENCES "media_assets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "media_usages" ADD CONSTRAINT "media_usages_mediaAssetId_fkey" FOREIGN KEY ("mediaAssetId") REFERENCES "media_assets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "media_moderation_results" ADD CONSTRAINT "media_moderation_results_mediaAssetId_fkey" FOREIGN KEY ("mediaAssetId") REFERENCES "media_assets"("id") ON DELETE CASCADE ON UPDATE CASCADE;
