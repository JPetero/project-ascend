import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { CapabilityService } from './capability.service';
import { AppCapability, PlanTier } from './capability.util';

describe('CapabilityService', () => {
  let service: CapabilityService;
  let prisma: { userSubscription: { findUnique: jest.Mock } };

  beforeEach(async () => {
    prisma = { userSubscription: { findUnique: jest.fn() } };

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
