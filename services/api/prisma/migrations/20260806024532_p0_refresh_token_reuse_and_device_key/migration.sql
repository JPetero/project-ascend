-- DropIndex
DROP INDEX "device_connections_userId_provider_key";

-- AlterTable
ALTER TABLE "device_connections" ADD COLUMN     "connectionKey" TEXT NOT NULL DEFAULT 'default';

-- AlterTable
ALTER TABLE "refresh_tokens" ADD COLUMN     "reusedAt" TIMESTAMP(3);

-- CreateIndex
CREATE UNIQUE INDEX "device_connections_userId_provider_connectionKey_key" ON "device_connections"("userId", "provider", "connectionKey");

