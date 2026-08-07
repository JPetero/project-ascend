-- CreateEnum
CREATE TYPE "CommunityProfileVisibility" AS ENUM ('PRIVATE', 'FRIENDS', 'FOLLOWERS', 'PUBLIC');

-- CreateEnum
CREATE TYPE "GalleryCategory" AS ENUM ('PROGRESS', 'WORKOUTS', 'MEALS', 'CARDIO', 'ACHIEVEMENTS', 'VISION', 'SHARED', 'PRIVATE');

-- CreateEnum
CREATE TYPE "GalleryVisibility" AS ENUM ('PRIVATE', 'SHARED');

-- CreateEnum
CREATE TYPE "GalleryPoseTag" AS ENUM ('FRONT', 'SIDE', 'BACK');

-- AlterTable
ALTER TABLE "community_profiles" ADD COLUMN     "avatarMediaAssetId" TEXT,
ADD COLUMN     "coverMediaAssetId" TEXT,
ADD COLUMN     "visibility" "CommunityProfileVisibility" NOT NULL DEFAULT 'PUBLIC';

-- CreateTable
CREATE TABLE "gallery_albums" (
    "id" TEXT NOT NULL,
    "ownerId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "category" "GalleryCategory" NOT NULL DEFAULT 'PRIVATE',
    "visibility" "GalleryVisibility" NOT NULL DEFAULT 'PRIVATE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "gallery_albums_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "gallery_media" (
    "id" TEXT NOT NULL,
    "albumId" TEXT NOT NULL,
    "mediaAssetId" TEXT NOT NULL,
    "note" TEXT,
    "poseTag" "GalleryPoseTag",
    "weightNote" TEXT,
    "capturedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "gallery_media_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "gallery_albums_ownerId_createdAt_idx" ON "gallery_albums"("ownerId", "createdAt");

-- CreateIndex
CREATE INDEX "gallery_media_albumId_createdAt_idx" ON "gallery_media"("albumId", "createdAt");

-- CreateIndex
CREATE INDEX "gallery_media_mediaAssetId_idx" ON "gallery_media"("mediaAssetId");

-- AddForeignKey
ALTER TABLE "community_profiles" ADD CONSTRAINT "community_profiles_avatarMediaAssetId_fkey" FOREIGN KEY ("avatarMediaAssetId") REFERENCES "media_assets"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "community_profiles" ADD CONSTRAINT "community_profiles_coverMediaAssetId_fkey" FOREIGN KEY ("coverMediaAssetId") REFERENCES "media_assets"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gallery_albums" ADD CONSTRAINT "gallery_albums_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gallery_media" ADD CONSTRAINT "gallery_media_albumId_fkey" FOREIGN KEY ("albumId") REFERENCES "gallery_albums"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gallery_media" ADD CONSTRAINT "gallery_media_mediaAssetId_fkey" FOREIGN KEY ("mediaAssetId") REFERENCES "media_assets"("id") ON DELETE CASCADE ON UPDATE CASCADE;
