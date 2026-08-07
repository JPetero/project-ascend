import { Test } from '@nestjs/testing';
import { CapabilityService } from '../../common/entitlements/capability.service';
import { PlanTier } from '../../common/entitlements/capability.util';
import { PrismaService } from '../../prisma/prisma.service';
import { SubscriptionsService } from './subscriptions.service';

describe('SubscriptionsService', () => {
  let service: SubscriptionsService;
  let prisma: {
    affordabilityEligibility: { findUnique: jest.Mock; upsert: jest.Mock };
  };
  let capabilityService: { getPlanTier: jest.Mock };

  beforeEach(async () => {
    prisma = {
      affordabilityEligibility: { findUnique: jest.fn(), upsert: jest.fn() },
    };
    capabilityService = { getPlanTier: jest.fn().mockResolvedValue(PlanTier.FREE) };

    const moduleRef = await Test.createTestingModule({
      providers: [
        SubscriptionsService,
        { provide: PrismaService, useValue: prisma },
        { provide: CapabilityService, useValue: capabilityService },
      ],
    }).compile();

    service = moduleRef.get(SubscriptionsService);
  });

  describe('getPricing', () => {
    it('returns a USD and a PHP pricing point, each with a lower eligible amount', () => {
      const pricing = service.getPricing();

      const usd = pricing.find((p) => p.currency === 'USD')!;
      const php = pricing.find((p) => p.currency === 'PHP')!;
      expect(usd.eligibleAmount).toBeLessThan(usd.standardAmount);
      expect(php.eligibleAmount).toBeLessThan(php.standardAmount);
    });
  });

  describe('getMyStatus', () => {
    it('reports no eligibility program when none was applied for', async () => {
      prisma.affordabilityEligibility.findUnique.mockResolvedValue(null);

      const status = await service.getMyStatus('user-1');

      expect(status).toEqual({ tier: PlanTier.FREE, eligibility: null });
    });

    it('includes the eligibility program and status once applied', async () => {
      prisma.affordabilityEligibility.findUnique.mockResolvedValue({
        userId: 'user-1',
        program: 'STUDENT',
        status: 'PENDING',
      });

      const status = await service.getMyStatus('user-1');

      expect(status.eligibility).toEqual({ program: 'STUDENT', status: 'PENDING' });
    });
  });

  describe('applyForEligibility', () => {
    it('upserts keyed on userId so re-applying resets to PENDING', async () => {
      prisma.affordabilityEligibility.upsert.mockResolvedValue({
        userId: 'user-1',
        program: 'STUDENT',
        status: 'PENDING',
      });

      await service.applyForEligibility('user-1', { program: 'STUDENT' } as never);

      expect(prisma.affordabilityEligibility.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { userId: 'user-1' },
          update: expect.objectContaining({ status: 'PENDING' }),
        }),
      );
    });
  });
});
