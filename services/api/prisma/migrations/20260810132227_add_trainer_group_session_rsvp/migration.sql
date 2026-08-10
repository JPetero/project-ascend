-- CreateEnum
CREATE TYPE "TrainerGroupScheduledSessionRsvpStatus" AS ENUM ('GOING', 'MAYBE', 'DECLINED');

-- AlterEnum
ALTER TYPE "NotificationType" ADD VALUE 'GROUP_SESSION_CANCELED';

-- AlterTable
ALTER TABLE "trainer_group_scheduled_sessions" ADD COLUMN     "workoutPlanId" TEXT;

-- CreateTable
CREATE TABLE "trainer_group_scheduled_session_participants" (
    "id" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "status" "TrainerGroupScheduledSessionRsvpStatus" NOT NULL,
    "respondedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "trainer_group_scheduled_session_participants_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "trainer_group_scheduled_session_participants_sessionId_stat_idx" ON "trainer_group_scheduled_session_participants"("sessionId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "trainer_group_scheduled_session_participants_sessionId_user_key" ON "trainer_group_scheduled_session_participants"("sessionId", "userId");

-- AddForeignKey
ALTER TABLE "trainer_group_scheduled_sessions" ADD CONSTRAINT "trainer_group_scheduled_sessions_workoutPlanId_fkey" FOREIGN KEY ("workoutPlanId") REFERENCES "workout_plans"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trainer_group_scheduled_session_participants" ADD CONSTRAINT "trainer_group_scheduled_session_participants_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "trainer_group_scheduled_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trainer_group_scheduled_session_participants" ADD CONSTRAINT "trainer_group_scheduled_session_participants_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
