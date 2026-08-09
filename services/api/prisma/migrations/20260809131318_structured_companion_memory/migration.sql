/*
  Warnings:

  - You are about to drop the `companion_memories` table. If the table is not empty, all the data it contains will be lost.

*/
-- CreateEnum
CREATE TYPE "CompanionMemoryCategory" AS ENUM ('WORKOUT_PREFERENCE', 'EQUIPMENT', 'SCHEDULE_PREFERENCE', 'FOOD_PREFERENCE', 'DIETARY_RESTRICTION', 'GOAL', 'COACHING_STYLE', 'COMPANION_PREFERENCE', 'UNIT_PREFERENCE', 'ACCESSIBILITY_PREFERENCE');

-- DropForeignKey
ALTER TABLE "companion_memories" DROP CONSTRAINT "companion_memories_userId_fkey";

-- AlterTable
ALTER TABLE "preferences" ALTER COLUMN "aiMemoryEnabled" SET DEFAULT false;

-- DropTable
DROP TABLE "companion_memories";

-- CreateTable
CREATE TABLE "companion_memory_notes" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "category" "CompanionMemoryCategory" NOT NULL,
    "value" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "companion_memory_notes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "companion_memory_notes_userId_createdAt_idx" ON "companion_memory_notes"("userId", "createdAt");

-- AddForeignKey
ALTER TABLE "companion_memory_notes" ADD CONSTRAINT "companion_memory_notes_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
