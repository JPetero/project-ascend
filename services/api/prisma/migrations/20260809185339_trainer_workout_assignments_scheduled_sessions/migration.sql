-- CreateEnum
CREATE TYPE "WorkoutAssignmentStatus" AS ENUM ('PENDING', 'ACCEPTED', 'COMPLETED', 'CANCELED');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "NotificationType" ADD VALUE 'WORKOUT_ASSIGNED';
ALTER TYPE "NotificationType" ADD VALUE 'GROUP_SESSION_SCHEDULED';

-- CreateTable
CREATE TABLE "workout_assignments" (
    "id" TEXT NOT NULL,
    "groupId" TEXT NOT NULL,
    "assignedById" TEXT NOT NULL,
    "assigneeId" TEXT NOT NULL,
    "sourcePlanId" TEXT NOT NULL,
    "assignedPlanId" TEXT,
    "note" TEXT,
    "dueAt" TIMESTAMP(3),
    "status" "WorkoutAssignmentStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "completedAt" TIMESTAMP(3),

    CONSTRAINT "workout_assignments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trainer_group_scheduled_sessions" (
    "id" TEXT NOT NULL,
    "groupId" TEXT NOT NULL,
    "createdById" TEXT NOT NULL,
    "title" TEXT,
    "scheduledAt" TIMESTAMP(3) NOT NULL,
    "durationMinutes" INTEGER,
    "location" TEXT,
    "videoLink" TEXT,
    "description" TEXT,
    "canceledAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "trainer_group_scheduled_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "workout_assignments_groupId_idx" ON "workout_assignments"("groupId");

-- CreateIndex
CREATE INDEX "workout_assignments_assigneeId_status_idx" ON "workout_assignments"("assigneeId", "status");

-- CreateIndex
CREATE INDEX "trainer_group_scheduled_sessions_groupId_scheduledAt_idx" ON "trainer_group_scheduled_sessions"("groupId", "scheduledAt");

-- AddForeignKey
ALTER TABLE "workout_assignments" ADD CONSTRAINT "workout_assignments_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "trainer_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "workout_assignments" ADD CONSTRAINT "workout_assignments_assignedById_fkey" FOREIGN KEY ("assignedById") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "workout_assignments" ADD CONSTRAINT "workout_assignments_assigneeId_fkey" FOREIGN KEY ("assigneeId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "workout_assignments" ADD CONSTRAINT "workout_assignments_sourcePlanId_fkey" FOREIGN KEY ("sourcePlanId") REFERENCES "workout_plans"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "workout_assignments" ADD CONSTRAINT "workout_assignments_assignedPlanId_fkey" FOREIGN KEY ("assignedPlanId") REFERENCES "workout_plans"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trainer_group_scheduled_sessions" ADD CONSTRAINT "trainer_group_scheduled_sessions_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "trainer_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trainer_group_scheduled_sessions" ADD CONSTRAINT "trainer_group_scheduled_sessions_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
