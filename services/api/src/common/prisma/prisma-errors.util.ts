import { Prisma } from '@prisma/client';

/**
 * True when a Prisma operation failed because its target row didn't exist
 * (error code P2025 — "Record to update/delete not found"). Lets services
 * rely on the database's own existence check instead of an extra
 * find-then-act round trip before every update/delete.
 */
export function isPrismaNotFoundError(error: unknown): boolean {
  return error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2025';
}
