-- AlterTable
ALTER TABLE "foods" ADD COLUMN     "slug" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "foods_slug_key" ON "foods"("slug");

