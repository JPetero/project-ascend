-- CreateEnum
CREATE TYPE "SyncOperationStatus" AS ENUM ('PROCESSING', 'COMPLETED', 'FAILED');

-- CreateEnum
CREATE TYPE "FoodSourceType" AS ENUM ('SEED', 'USER');

-- CreateEnum
CREATE TYPE "MealType" AS ENUM ('BREAKFAST', 'LUNCH', 'DINNER', 'SNACK');

-- AlterTable
ALTER TABLE "workout_plans" ADD COLUMN     "archivedAt" TIMESTAMP(3),
ADD COLUMN     "description" TEXT;

-- AlterTable
ALTER TABLE "workout_sessions" ADD COLUMN     "difficultyRating" INTEGER;

-- AlterTable
ALTER TABLE "workout_sets" ADD COLUMN     "rpe" DOUBLE PRECISION;

-- CreateTable
CREATE TABLE "workout_session_substitutions" (
    "id" TEXT NOT NULL,
    "workoutSessionId" TEXT NOT NULL,
    "originalExerciseId" TEXT NOT NULL,
    "substituteExerciseId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "workout_session_substitutions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sync_operations" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "idempotencyKey" TEXT NOT NULL,
    "entityType" TEXT NOT NULL,
    "operationType" TEXT NOT NULL,
    "localEntityId" TEXT,
    "clientCreatedAt" TIMESTAMP(3),
    "payloadVersion" INTEGER NOT NULL DEFAULT 1,
    "status" "SyncOperationStatus" NOT NULL DEFAULT 'PROCESSING',
    "resultEntityId" TEXT,
    "resultPayload" JSONB,
    "errorMessage" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "sync_operations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "foods" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "alternateName" TEXT,
    "brand" TEXT,
    "sourceType" "FoodSourceType" NOT NULL DEFAULT 'SEED',
    "ownerId" TEXT,
    "servingDescription" TEXT NOT NULL,
    "servingGrams" DOUBLE PRECISION,
    "caloriesPerServing" DOUBLE PRECISION NOT NULL,
    "proteinGramsPerServing" DOUBLE PRECISION NOT NULL,
    "carbGramsPerServing" DOUBLE PRECISION NOT NULL,
    "fatGramsPerServing" DOUBLE PRECISION NOT NULL,
    "fiberGramsPerServing" DOUBLE PRECISION,
    "sodiumMgPerServing" DOUBLE PRECISION,
    "isEstimated" BOOLEAN NOT NULL DEFAULT true,
    "archivedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "foods_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "food_servings" (
    "id" TEXT NOT NULL,
    "foodId" TEXT NOT NULL,
    "label" TEXT NOT NULL,
    "grams" DOUBLE PRECISION,
    "isDefault" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "food_servings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "meal_entries" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "foodId" TEXT NOT NULL,
    "foodServingId" TEXT,
    "mealType" "MealType" NOT NULL,
    "date" DATE NOT NULL,
    "quantity" DOUBLE PRECISION NOT NULL,
    "loggedByGrams" BOOLEAN NOT NULL DEFAULT false,
    "gramsLogged" DOUBLE PRECISION,
    "calories" DOUBLE PRECISION NOT NULL,
    "proteinGrams" DOUBLE PRECISION NOT NULL,
    "carbGrams" DOUBLE PRECISION NOT NULL,
    "fatGrams" DOUBLE PRECISION NOT NULL,
    "fiberGrams" DOUBLE PRECISION,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "meal_entries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "macro_targets" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "calorieTarget" INTEGER NOT NULL,
    "proteinGramsTarget" INTEGER NOT NULL,
    "carbGramsTarget" INTEGER NOT NULL,
    "fatGramsTarget" INTEGER NOT NULL,
    "fiberGramsTarget" INTEGER,
    "isEstimatedDefault" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "macro_targets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "water_entries" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "amountMl" INTEGER NOT NULL,
    "loggedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "water_entries_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "workout_session_substitutions_workoutSessionId_idx" ON "workout_session_substitutions"("workoutSessionId");

-- CreateIndex
CREATE UNIQUE INDEX "workout_session_substitutions_workoutSessionId_originalExer_key" ON "workout_session_substitutions"("workoutSessionId", "originalExerciseId");

-- CreateIndex
CREATE INDEX "sync_operations_userId_idx" ON "sync_operations"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "sync_operations_userId_idempotencyKey_key" ON "sync_operations"("userId", "idempotencyKey");

-- CreateIndex
CREATE INDEX "foods_ownerId_idx" ON "foods"("ownerId");

-- CreateIndex
CREATE INDEX "foods_name_idx" ON "foods"("name");

-- CreateIndex
CREATE INDEX "food_servings_foodId_idx" ON "food_servings"("foodId");

-- CreateIndex
CREATE INDEX "meal_entries_userId_date_idx" ON "meal_entries"("userId", "date");

-- CreateIndex
CREATE UNIQUE INDEX "macro_targets_userId_key" ON "macro_targets"("userId");

-- CreateIndex
CREATE INDEX "water_entries_userId_date_idx" ON "water_entries"("userId", "date");

-- AddForeignKey
ALTER TABLE "workout_session_substitutions" ADD CONSTRAINT "workout_session_substitutions_workoutSessionId_fkey" FOREIGN KEY ("workoutSessionId") REFERENCES "workout_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "workout_session_substitutions" ADD CONSTRAINT "workout_session_substitutions_originalExerciseId_fkey" FOREIGN KEY ("originalExerciseId") REFERENCES "exercises"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "workout_session_substitutions" ADD CONSTRAINT "workout_session_substitutions_substituteExerciseId_fkey" FOREIGN KEY ("substituteExerciseId") REFERENCES "exercises"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sync_operations" ADD CONSTRAINT "sync_operations_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "foods" ADD CONSTRAINT "foods_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "food_servings" ADD CONSTRAINT "food_servings_foodId_fkey" FOREIGN KEY ("foodId") REFERENCES "foods"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "meal_entries" ADD CONSTRAINT "meal_entries_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "meal_entries" ADD CONSTRAINT "meal_entries_foodId_fkey" FOREIGN KEY ("foodId") REFERENCES "foods"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "meal_entries" ADD CONSTRAINT "meal_entries_foodServingId_fkey" FOREIGN KEY ("foodServingId") REFERENCES "food_servings"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "macro_targets" ADD CONSTRAINT "macro_targets_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "water_entries" ADD CONSTRAINT "water_entries_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

