-- CreateEnum
CREATE TYPE "JointWorkoutSessionStatus" AS ENUM ('CREATED', 'IN_PROGRESS', 'FINISHED', 'CANCELED');

-- CreateEnum
CREATE TYPE "JointWorkoutParticipantStatus" AS ENUM ('INVITED', 'ACCEPTED', 'DECLINED', 'READY', 'ACTIVE', 'FINISHED', 'LEFT');

-- CreateEnum
CREATE TYPE "JointWorkoutEventType" AS ENUM ('INVITED', 'ACCEPTED', 'DECLINED', 'READY', 'STARTED', 'PROGRESS', 'FINISHED', 'LEFT', 'CANCELED');

-- CreateTable
CREATE TABLE "joint_workout_sessions" (
    "id" TEXT NOT NULL,
    "hostId" TEXT NOT NULL,
    "title" TEXT,
    "status" "JointWorkoutSessionStatus" NOT NULL DEFAULT 'CREATED',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "startedAt" TIMESTAMP(3),
    "finishedAt" TIMESTAMP(3),
    "canceledAt" TIMESTAMP(3),

    CONSTRAINT "joint_workout_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "joint_workout_participants" (
    "id" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "status" "JointWorkoutParticipantStatus" NOT NULL DEFAULT 'INVITED',
    "invitedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "respondedAt" TIMESTAMP(3),
    "readyAt" TIMESTAMP(3),
    "finishedAt" TIMESTAMP(3),
    "leftAt" TIMESTAMP(3),

    CONSTRAINT "joint_workout_participants_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "joint_workout_shared_results" (
    "id" TEXT NOT NULL,
    "participantId" TEXT NOT NULL,
    "exerciseName" TEXT,
    "setsCompleted" INTEGER,
    "durationSeconds" INTEGER,
    "distanceMeters" DOUBLE PRECISION,
    "isPersonalRecord" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "joint_workout_shared_results_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "joint_workout_events" (
    "id" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "userId" TEXT,
    "type" "JointWorkoutEventType" NOT NULL,
    "message" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "joint_workout_events_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "joint_workout_sessions_hostId_idx" ON "joint_workout_sessions"("hostId");

-- CreateIndex
CREATE INDEX "joint_workout_participants_userId_status_idx" ON "joint_workout_participants"("userId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "joint_workout_participants_sessionId_userId_key" ON "joint_workout_participants"("sessionId", "userId");

-- CreateIndex
CREATE INDEX "joint_workout_shared_results_participantId_idx" ON "joint_workout_shared_results"("participantId");

-- CreateIndex
CREATE INDEX "joint_workout_events_sessionId_createdAt_idx" ON "joint_workout_events"("sessionId", "createdAt");

-- AddForeignKey
ALTER TABLE "joint_workout_sessions" ADD CONSTRAINT "joint_workout_sessions_hostId_fkey" FOREIGN KEY ("hostId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "joint_workout_participants" ADD CONSTRAINT "joint_workout_participants_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "joint_workout_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "joint_workout_participants" ADD CONSTRAINT "joint_workout_participants_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "joint_workout_shared_results" ADD CONSTRAINT "joint_workout_shared_results_participantId_fkey" FOREIGN KEY ("participantId") REFERENCES "joint_workout_participants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "joint_workout_events" ADD CONSTRAINT "joint_workout_events_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "joint_workout_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "joint_workout_events" ADD CONSTRAINT "joint_workout_events_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
