-- CreateEnum
CREATE TYPE "NutrientCategoryCode" AS ENUM ('MACRONUTRIENT', 'MINERAL', 'VITAMIN');

-- CreateTable
CREATE TABLE "nutrient_categories" (
    "id" TEXT NOT NULL,
    "code" "NutrientCategoryCode" NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,

    CONSTRAINT "nutrient_categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "nutrient_articles" (
    "id" TEXT NOT NULL,
    "categoryId" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "summary" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "safetyNote" TEXT NOT NULL,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "nutrient_articles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "nutrient_food_sources" (
    "id" TEXT NOT NULL,
    "articleId" TEXT NOT NULL,
    "foodName" TEXT NOT NULL,
    "amount" TEXT NOT NULL,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "nutrient_food_sources_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "nutrient_references" (
    "id" TEXT NOT NULL,
    "articleId" TEXT NOT NULL,
    "label" TEXT NOT NULL,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "nutrient_references_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "saved_nutrient_articles" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "articleId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "saved_nutrient_articles_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "nutrient_categories_code_key" ON "nutrient_categories"("code");

-- CreateIndex
CREATE UNIQUE INDEX "nutrient_articles_slug_key" ON "nutrient_articles"("slug");

-- CreateIndex
CREATE INDEX "nutrient_articles_categoryId_idx" ON "nutrient_articles"("categoryId");

-- CreateIndex
CREATE INDEX "nutrient_food_sources_articleId_idx" ON "nutrient_food_sources"("articleId");

-- CreateIndex
CREATE INDEX "nutrient_references_articleId_idx" ON "nutrient_references"("articleId");

-- CreateIndex
CREATE INDEX "saved_nutrient_articles_userId_idx" ON "saved_nutrient_articles"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "saved_nutrient_articles_userId_articleId_key" ON "saved_nutrient_articles"("userId", "articleId");

-- AddForeignKey
ALTER TABLE "nutrient_articles" ADD CONSTRAINT "nutrient_articles_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "nutrient_categories"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "nutrient_food_sources" ADD CONSTRAINT "nutrient_food_sources_articleId_fkey" FOREIGN KEY ("articleId") REFERENCES "nutrient_articles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "nutrient_references" ADD CONSTRAINT "nutrient_references_articleId_fkey" FOREIGN KEY ("articleId") REFERENCES "nutrient_articles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "saved_nutrient_articles" ADD CONSTRAINT "saved_nutrient_articles_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "saved_nutrient_articles" ADD CONSTRAINT "saved_nutrient_articles_articleId_fkey" FOREIGN KEY ("articleId") REFERENCES "nutrient_articles"("id") ON DELETE CASCADE ON UPDATE CASCADE;
