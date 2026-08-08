-- CreateEnum
CREATE TYPE "VisionExercise" AS ENUM ('BODYWEIGHT_SQUAT', 'BICEPS_CURL', 'SHOULDER_PRESS');

-- CreateEnum
CREATE TYPE "FormObservationSeverity" AS ENUM ('INFO', 'COACHING_CUE', 'CHECK_FORM');

-- CreateTable
CREATE TABLE "vision_analysis_sessions" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "exercise" "VisionExercise" NOT NULL,
    "startedAt" TIMESTAMP(3) NOT NULL,
    "completedAt" TIMESTAMP(3),
    "autoRepCount" INTEGER NOT NULL,
    "correctedRepCount" INTEGER NOT NULL,
    "analysisVersion" TEXT NOT NULL,
    "mediaAssetId" TEXT,
    "workoutSessionId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "vision_analysis_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vision_form_observations" (
    "id" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "severity" "FormObservationSeverity" NOT NULL,
    "confidence" DOUBLE PRECISION NOT NULL,
    "occurredAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "vision_form_observations_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "vision_analysis_sessions_userId_createdAt_idx" ON "vision_analysis_sessions"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "vision_analysis_sessions_userId_exercise_idx" ON "vision_analysis_sessions"("userId", "exercise");

-- CreateIndex
CREATE INDEX "vision_form_observations_sessionId_idx" ON "vision_form_observations"("sessionId");

-- AddForeignKey
ALTER TABLE "vision_analysis_sessions" ADD CONSTRAINT "vision_analysis_sessions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vision_form_observations" ADD CONSTRAINT "vision_form_observations_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "vision_analysis_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

