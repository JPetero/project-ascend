-- CreateEnum
CREATE TYPE "CardioSessionSource" AS ENUM ('MANUAL', 'LIVE_GPS', 'WEARABLE');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "CardioActivityType" ADD VALUE 'JOG';
ALTER TYPE "CardioActivityType" ADD VALUE 'SPRINT';
ALTER TYPE "CardioActivityType" ADD VALUE 'HIKE';
ALTER TYPE "CardioActivityType" ADD VALUE 'WHEELCHAIR';

-- AlterTable
ALTER TABLE "cardio_sessions" ADD COLUMN     "encodedRoute" TEXT,
ADD COLUMN     "routePointCount" INTEGER,
ADD COLUMN     "source" "CardioSessionSource" NOT NULL DEFAULT 'MANUAL';
