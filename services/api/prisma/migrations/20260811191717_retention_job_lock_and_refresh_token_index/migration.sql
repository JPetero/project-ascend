-- CreateTable
CREATE TABLE "scheduled_job_locks" (
    "jobName" TEXT NOT NULL,
    "lockedUntil" TIMESTAMP(3) NOT NULL,
    "lockedBy" TEXT NOT NULL,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "scheduled_job_locks_pkey" PRIMARY KEY ("jobName")
);

-- CreateIndex
CREATE INDEX "refresh_tokens_userId_createdAt_idx" ON "refresh_tokens"("userId", "createdAt");
