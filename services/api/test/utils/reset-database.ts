import { PrismaClient } from '@prisma/client';

/** Truncates all tables between e2e test runs, respecting FK order. */
export async function resetDatabase(prisma: PrismaClient): Promise<void> {
  await prisma.auditEvent.deleteMany();
  await prisma.deviceConnection.deleteMany();
  await prisma.workoutSchedule.deleteMany();
  await prisma.equipment.deleteMany();
  await prisma.preference.deleteMany();
  await prisma.profile.deleteMany();
  await prisma.refreshToken.deleteMany();
  await prisma.user.deleteMany();
}
