-- AlterTable
ALTER TABLE "preferences" ADD COLUMN     "defaultGalleryVisibility" "GalleryVisibility" NOT NULL DEFAULT 'PRIVATE',
ADD COLUMN     "defaultHideCardioRoute" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "defaultPostVisibility" "CommunityVisibility" NOT NULL DEFAULT 'PUBLIC',
ADD COLUMN     "progressPhotoDefaultVisibility" "GalleryVisibility" NOT NULL DEFAULT 'PRIVATE';

