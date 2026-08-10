import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { CapabilityService } from './capability.service';
import { AppCapability, PlanTier } from './capability.util';

describe('CapabilityService', () => {
  let service: CapabilityService;
  let prisma: { userSubscription: { findUnique: jest.Mock; update: jest.Mock } };

  beforeEach(async () => {
    prisma = { userSubscription: { findUnique: jest.fn(), update: jest.fn() } };

    const moduleRef = await Test.createTestingModule({
      providers: [CapabilityService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = moduleRef.get(CapabilityService);
  });

  describe('getPlanTier', () => {
    it('resolves to FREE when the user has no subscription row', async () => {
      prisma.userSubscription.findUnique.mockResolvedValue(null);

      expect(await service.getPlanTier('user-1')).toBe(PlanTier.FREE);
    });

    it('resolves to PREMIUM when the row says PREMIUM', async () => {
      prisma.userSubscription.findUnique.mockResolvedValue({
        userId: 'user-1',
        tier: 'PREMIUM',
      });

      expect(await service.getPlanTier('user-1')).toBe(PlanTier.PREMIUM);
    });

    it('resolves to FREE for a row explicitly marked FREE', async () => {
      prisma.userSubscription.findUnique.mockResolvedValue({ userId: 'user-1', tier: 'FREE' });

      expect(await service.getPlanTier('user-1')).toBe(PlanTier.FREE);
    });

    it('resolves to PREMIUM with no expiresAt set (legacy row / manual grant)', async () => {
      prisma.userSubscription.findUnique.mockResolvedValue({
        userId: 'user-1',
        tier: 'PREMIUM',
        expiresAt: null,
      });

      expect(await service.getPlanTier('user-1')).toBe(PlanTier.PREMIUM);
      expect(prisma.userSubscription.update).not.toHaveBeenCalled();
    });

    it('resolves to PREMIUM while expiresAt is still in the future', async () => {
      prisma.userSubscription.findUnique.mockResolvedValue({
        userId: 'user-1',
        tier: 'PREMIUM',
        expiresAt: new Date(Date.now() + 60_000),
      });

      expect(await service.getPlanTier('user-1')).toBe(PlanTier.PREMIUM);
      expect(prisma.userSubscription.update).not.toHaveBeenCalled();
    });

    it('purchase reconciliation (Build Session 12 Part 22) — downgrades to FREE and persists it once expiresAt has passed', async () => {
      prisma.userSubscription.findUnique.mockResolvedValue({
        userId: 'user-1',
        tier: 'PREMIUM',
        expiresAt: new Date(Date.now() - 60_000),
      });

      expect(await service.getPlanTier('user-1')).toBe(PlanTier.FREE);
      expect(prisma.userSubscription.update).toHaveBeenCalledWith({
        where: { userId: 'user-1' },
        data: { tier: 'FREE' },
      });
    });
  });

  describe('hasCapabilityForUser', () => {
    it('a free capability is available even with no subscription row', async () => {
      prisma.userSubscription.findUnique.mockResolvedValue(null);

      expect(await service.hasCapabilityForUser('user-1', AppCapability.WORKOUT_LOGGING)).toBe(
        true,
      );
    });

    it('a premium capability is unavailable with no subscription row', async () => {
      prisma.userSubscription.findUnique.mockResolvedValue(null);

      expect(await service.hasCapabilityForUser('user-1', AppCapability.VISION_ACCESS)).toBe(false);
    });

    it('a premium capability becomes available once the row says PREMIUM', async () => {
      prisma.userSubscription.findUnique.mockResolvedValue({
        userId: 'user-1',
        tier: 'PREMIUM',
      });

      expect(await service.hasCapabilityForUser('user-1', AppCapability.VISION_ACCESS)).toBe(true);
    });
  });
});
