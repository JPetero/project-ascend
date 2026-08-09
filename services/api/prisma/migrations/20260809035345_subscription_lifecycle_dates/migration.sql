-- AlterTable
ALTER TABLE "user_subscriptions" ADD COLUMN     "expiresAt" TIMESTAMP(3),
ADD COLUMN     "willRenew" BOOLEAN;
