-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "NotificationType" ADD VALUE 'SUPPORT_REPLY';
ALTER TYPE "NotificationType" ADD VALUE 'SUPPORT_STATUS_CHANGED';
ALTER TYPE "NotificationType" ADD VALUE 'MODERATION_DECISION';
ALTER TYPE "NotificationType" ADD VALUE 'MODERATION_APPEAL_UPDATE';
ALTER TYPE "NotificationType" ADD VALUE 'PROMOTE_REVIEW';
ALTER TYPE "NotificationType" ADD VALUE 'ELIGIBILITY_VERIFICATION_UPDATE';
