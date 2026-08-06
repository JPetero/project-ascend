-- CreateEnum
CREATE TYPE "MeasurementType" AS ENUM ('REPS_WEIGHT', 'REPS_ONLY', 'DURATION', 'DISTANCE_DURATION', 'ASSISTED_WEIGHT', 'BODYWEIGHT');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "PersonalRecordType" ADD VALUE 'ESTIMATED_ONE_REP_MAX';
ALTER TYPE "PersonalRecordType" ADD VALUE 'BEST_PACE';

-- AlterTable
ALTER TABLE "exercises" ADD COLUMN     "measurementType" "MeasurementType" NOT NULL DEFAULT 'REPS_WEIGHT';

-- AlterTable
ALTER TABLE "workout_exercises" ADD COLUMN     "targetDistanceMeters" DOUBLE PRECISION;

-- AlterTable
ALTER TABLE "workout_plan_exercises" ADD COLUMN     "targetDistanceMeters" DOUBLE PRECISION;

