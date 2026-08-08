-- CreateEnum
CREATE TYPE "AdminPermission" AS ENUM ('MODERATE_COMMUNITY', 'REVIEW_ELIGIBILITY', 'MANAGE_SUPPORT', 'REVIEW_PROMOTIONS', 'MANAGE_ADMINS');

-- CreateTable
CREATE TABLE "admin_permission_grants" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "permission" "AdminPermission" NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "admin_permission_grants_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "admin_permission_grants_userId_idx" ON "admin_permission_grants"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "admin_permission_grants_userId_permission_key" ON "admin_permission_grants"("userId", "permission");

-- AddForeignKey
ALTER TABLE "admin_permission_grants" ADD CONSTRAINT "admin_permission_grants_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Backfill: every account that was already ADMIN before this migration
-- had unconditional access to all four existing admin surfaces (there
-- was no narrower concept than "is ADMIN"). Preserve that access
-- exactly rather than silently locking existing staff out. Deliberately
-- NOT backfilling MANAGE_ADMINS — the first grant of that permission is
-- an out-of-band DB operation, same bootstrap posture as granting
-- UserRole.ADMIN itself always has been.
INSERT INTO "admin_permission_grants" ("id", "userId", "permission")
SELECT gen_random_uuid()::text, "id", permission."value"::"AdminPermission"
FROM "users"
CROSS JOIN (
  VALUES ('MODERATE_COMMUNITY'), ('REVIEW_ELIGIBILITY'), ('MANAGE_SUPPORT'), ('REVIEW_PROMOTIONS')
) AS permission("value")
WHERE "users"."role" = 'ADMIN';
