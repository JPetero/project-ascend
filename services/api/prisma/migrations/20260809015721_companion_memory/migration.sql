-- CreateTable
CREATE TABLE "companion_memories" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "notes" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "companion_memories_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "companion_memories_userId_key" ON "companion_memories"("userId");

-- AddForeignKey
ALTER TABLE "companion_memories" ADD CONSTRAINT "companion_memories_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

