-- CreateEnum
CREATE TYPE "TrainerVerificationStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- AlterEnum
ALTER TYPE "AdminPermission" ADD VALUE 'REVIEW_TRAINER_VERIFICATION';

-- AlterTable
ALTER TABLE "community_profiles" ADD COLUMN     "verifiedTrainer" BOOLEAN NOT NULL DEFAULT false;

-- CreateTable
CREATE TABLE "trainer_verification_applications" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "credentials" TEXT NOT NULL,
    "status" "TrainerVerificationStatus" NOT NULL DEFAULT 'PENDING',
    "submittedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reviewedAt" TIMESTAMP(3),

    CONSTRAINT "trainer_verification_applications_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "trainer_verification_applications_userId_key" ON "trainer_verification_applications"("userId");

-- AddForeignKey
ALTER TABLE "trainer_verification_applications" ADD CONSTRAINT "trainer_verification_applications_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
