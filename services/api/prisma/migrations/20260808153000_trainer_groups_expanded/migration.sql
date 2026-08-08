-- AlterEnum
ALTER TYPE "TrainerGroupMemberRole" ADD VALUE 'MODERATOR';

-- CreateTable
CREATE TABLE "trainer_group_announcements" (
    "id" TEXT NOT NULL,
    "groupId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "trainer_group_announcements_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "trainer_group_announcements_groupId_createdAt_idx" ON "trainer_group_announcements"("groupId", "createdAt");

-- AddForeignKey
ALTER TABLE "trainer_group_announcements" ADD CONSTRAINT "trainer_group_announcements_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "trainer_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trainer_group_announcements" ADD CONSTRAINT "trainer_group_announcements_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
