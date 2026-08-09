-- AlterTable
ALTER TABLE "preferences" ADD COLUMN     "conversationHistoryEnabled" BOOLEAN NOT NULL DEFAULT true;

-- CreateTable
CREATE TABLE "companion_conversations" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "companion" "Companion" NOT NULL,
    "title" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "companion_conversations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "companion_chat_messages" (
    "id" TEXT NOT NULL,
    "conversationId" TEXT NOT NULL,
    "isFromUser" BOOLEAN NOT NULL,
    "text" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "companion_chat_messages_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "companion_conversations_userId_updatedAt_idx" ON "companion_conversations"("userId", "updatedAt");

-- CreateIndex
CREATE INDEX "companion_chat_messages_conversationId_createdAt_idx" ON "companion_chat_messages"("conversationId", "createdAt");

-- AddForeignKey
ALTER TABLE "companion_conversations" ADD CONSTRAINT "companion_conversations_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "companion_chat_messages" ADD CONSTRAINT "companion_chat_messages_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "companion_conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;
