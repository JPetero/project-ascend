-- CreateEnum
CREATE TYPE "HealthMetric" AS ENUM ('STEPS', 'HEART_RATE', 'RESTING_HEART_RATE', 'EXERCISE_SESSION', 'ACTIVE_CALORIES', 'DISTANCE', 'SLEEP', 'CYCLING_DISTANCE');

-- CreateTable
CREATE TABLE "health_metric_samples" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "metric" "HealthMetric" NOT NULL,
    "value" DOUBLE PRECISION NOT NULL,
    "unit" TEXT NOT NULL,
    "recordedAt" TIMESTAMP(3) NOT NULL,
    "recordedTimezone" TEXT,
    "sourceProvider" TEXT NOT NULL,
    "sourceDeviceId" TEXT,
    "externalId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "health_metric_samples_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "health_sync_cursors" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "metric" "HealthMetric" NOT NULL,
    "cursor" TEXT NOT NULL,
    "lastSyncedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "health_sync_cursors_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "health_metric_samples_userId_metric_recordedAt_idx" ON "health_metric_samples"("userId", "metric", "recordedAt");

-- CreateIndex
CREATE UNIQUE INDEX "health_metric_samples_userId_metric_sourceProvider_recorded_key" ON "health_metric_samples"("userId", "metric", "sourceProvider", "recordedAt");

-- CreateIndex
CREATE UNIQUE INDEX "health_sync_cursors_userId_provider_metric_key" ON "health_sync_cursors"("userId", "provider", "metric");

-- AddForeignKey
ALTER TABLE "health_metric_samples" ADD CONSTRAINT "health_metric_samples_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "health_sync_cursors" ADD CONSTRAINT "health_sync_cursors_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
