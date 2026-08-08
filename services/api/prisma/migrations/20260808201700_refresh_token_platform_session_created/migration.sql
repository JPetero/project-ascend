-- AlterTable
ALTER TABLE "refresh_tokens" ADD COLUMN     "platform" TEXT,
ADD COLUMN     "sessionCreatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

