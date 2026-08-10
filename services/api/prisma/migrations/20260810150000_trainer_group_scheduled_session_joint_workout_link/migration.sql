-- AlterTable
ALTER TABLE "trainer_group_scheduled_sessions" ADD COLUMN     "jointWorkoutSessionId" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "trainer_group_scheduled_sessions_jointWorkoutSessionId_key" ON "trainer_group_scheduled_sessions"("jointWorkoutSessionId");

-- AddForeignKey
ALTER TABLE "trainer_group_scheduled_sessions" ADD CONSTRAINT "trainer_group_scheduled_sessions_jointWorkoutSessionId_fkey" FOREIGN KEY ("jointWorkoutSessionId") REFERENCES "joint_workout_sessions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

