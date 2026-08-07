-- CreateEnum
CREATE TYPE "TrainerGroupMemberRole" AS ENUM ('OWNER', 'MEMBER');

-- CreateEnum
CREATE TYPE "TrainerGroupInvitationStatus" AS ENUM ('PENDING', 'ACCEPTED', 'DECLINED', 'CANCELED');

-- CreateTable
CREATE TABLE "trainer_groups" (
    "id" TEXT NOT NULL,
    "ownerId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "trainer_groups_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trainer_group_members" (
    "id" TEXT NOT NULL,
    "groupId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "role" "TrainerGroupMemberRole" NOT NULL DEFAULT 'MEMBER',
    "joinedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "trainer_group_members_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trainer_group_invitations" (
    "id" TEXT NOT NULL,
    "groupId" TEXT NOT NULL,
    "inviterId" TEXT NOT NULL,
    "inviteeId" TEXT NOT NULL,
    "status" "TrainerGroupInvitationStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "trainer_group_invitations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trainer_group_messages" (
    "id" TEXT NOT NULL,
    "groupId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "body" TEXT,
    "imageUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "trainer_group_messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trainer_group_shared_plans" (
    "id" TEXT NOT NULL,
    "groupId" TEXT NOT NULL,
    "workoutPlanId" TEXT NOT NULL,
    "sharedById" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "trainer_group_shared_plans_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "trainer_groups_ownerId_idx" ON "trainer_groups"("ownerId");

-- CreateIndex
CREATE INDEX "trainer_group_members_userId_idx" ON "trainer_group_members"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "trainer_group_members_groupId_userId_key" ON "trainer_group_members"("groupId", "userId");

-- CreateIndex
CREATE INDEX "trainer_group_invitations_inviteeId_status_idx" ON "trainer_group_invitations"("inviteeId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "trainer_group_invitations_groupId_inviteeId_key" ON "trainer_group_invitations"("groupId", "inviteeId");

-- CreateIndex
CREATE INDEX "trainer_group_messages_groupId_createdAt_idx" ON "trainer_group_messages"("groupId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "trainer_group_shared_plans_groupId_workoutPlanId_key" ON "trainer_group_shared_plans"("groupId", "workoutPlanId");

-- AddForeignKey
ALTER TABLE "trainer_groups" ADD CONSTRAINT "trainer_groups_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trainer_group_members" ADD CONSTRAINT "trainer_group_members_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "trainer_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trainer_group_members" ADD CONSTRAINT "trainer_group_members_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trainer_group_invitations" ADD CONSTRAINT "trainer_group_invitations_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "trainer_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trainer_group_invitations" ADD CONSTRAINT "trainer_group_invitations_inviterId_fkey" FOREIGN KEY ("inviterId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trainer_group_invitations" ADD CONSTRAINT "trainer_group_invitations_inviteeId_fkey" FOREIGN KEY ("inviteeId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trainer_group_messages" ADD CONSTRAINT "trainer_group_messages_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "trainer_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trainer_group_messages" ADD CONSTRAINT "trainer_group_messages_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trainer_group_shared_plans" ADD CONSTRAINT "trainer_group_shared_plans_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "trainer_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trainer_group_shared_plans" ADD CONSTRAINT "trainer_group_shared_plans_workoutPlanId_fkey" FOREIGN KEY ("workoutPlanId") REFERENCES "workout_plans"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trainer_group_shared_plans" ADD CONSTRAINT "trainer_group_shared_plans_sharedById_fkey" FOREIGN KEY ("sharedById") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
