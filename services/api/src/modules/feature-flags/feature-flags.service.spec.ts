import { NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { AscendFeatureKey } from './feature-flag-registry';
import { FeatureFlagsService } from './feature-flags.service';

describe('FeatureFlagsService', () => {
  let service: FeatureFlagsService;
  let prisma: {
    featureFlag: {
      findMany: jest.Mock;
      findUnique: jest.Mock;
      upsert: jest.Mock;
      delete: jest.Mock;
    };
  };

  beforeEach(async () => {
    prisma = {
      featureFlag: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn(),
        upsert: jest.fn(),
        delete: jest.fn(),
      },
    };

    const moduleRef = await Test.createTestingModule({
      providers: [FeatureFlagsService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = moduleRef.get(FeatureFlagsService);
  });

  describe('listAll', () => {
    it('returns every flag row ordered by key', async () => {
      prisma.featureFlag.findMany.mockResolvedValue([{ key: 'a' }]);

      const result = await service.listAll();

      expect(result).toEqual([{ key: 'a' }]);
      expect(prisma.featureFlag.findMany).toHaveBeenCalledWith({ orderBy: { key: 'asc' } });
    });
  });

  describe('listAllWithDefinitions', () => {
    it('includes every registered key even with zero rows in the database', async () => {
      prisma.featureFlag.findMany.mockResolvedValue([]);

      const result = await service.listAllWithDefinitions();

      const keys = result.map((entry) => entry.key);
      expect(keys).toEqual(expect.arrayContaining(Object.values(AscendFeatureKey)));
    });

    it('reports the registry default, risk, and hasOverride=false for a key with no row', async () => {
      prisma.featureFlag.findMany.mockResolvedValue([]);

      const result = await service.listAllWithDefinitions();

      const liveAi = result.find((entry) => entry.key === AscendFeatureKey.LIVE_AI)!;
      expect(liveAi).toMatchObject({
        enabled: false,
        defaultEnabled: false,
        risk: 'RISKY_EXTERNAL',
        hasOverride: false,
      });

      const trainerDashboard = result.find(
        (entry) => entry.key === AscendFeatureKey.TRAINER_DASHBOARD,
      )!;
      expect(trainerDashboard).toMatchObject({
        enabled: true,
        defaultEnabled: true,
        risk: 'SAFE_CORE',
        hasOverride: false,
      });
    });

    it('lets a stored row override the registry default', async () => {
      prisma.featureFlag.findMany.mockResolvedValue([
        {
          id: 'row-1',
          key: AscendFeatureKey.LIVE_AI,
          description: 'Custom description',
          enabled: true,
          rolloutPercentage: 100,
          createdAt: new Date('2026-01-01'),
          updatedAt: new Date('2026-01-02'),
        },
      ]);

      const result = await service.listAllWithDefinitions();

      const liveAi = result.find((entry) => entry.key === AscendFeatureKey.LIVE_AI)!;
      expect(liveAi).toMatchObject({
        enabled: true,
        hasOverride: true,
        id: 'row-1',
        description: 'Custom description',
      });
    });

    it('includes an ad-hoc (unregistered) key with defaultEnabled/risk null', async () => {
      prisma.featureFlag.findMany.mockResolvedValue([
        {
          id: 'row-2',
          key: 'some_experiment',
          description: null,
          enabled: true,
          rolloutPercentage: 100,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      ]);

      const result = await service.listAllWithDefinitions();

      const adHoc = result.find((entry) => entry.key === 'some_experiment')!;
      expect(adHoc).toMatchObject({ defaultEnabled: null, risk: null, hasOverride: true });
    });
  });

  describe('upsert', () => {
    it('creates a new flag with defaults when fields are omitted', async () => {
      prisma.featureFlag.upsert.mockResolvedValue({ key: 'new_flag' });

      await service.upsert('new_flag', {});

      expect(prisma.featureFlag.upsert).toHaveBeenCalledWith({
        where: { key: 'new_flag' },
        update: {},
        create: {
          key: 'new_flag',
          description: undefined,
          enabled: false,
          rolloutPercentage: 100,
        },
      });
    });

    it('passes through provided fields on update', async () => {
      prisma.featureFlag.upsert.mockResolvedValue({ key: 'existing' });

      await service.upsert('existing', { enabled: true, rolloutPercentage: 50 });

      expect(prisma.featureFlag.upsert).toHaveBeenCalledWith(
        expect.objectContaining({ update: { enabled: true, rolloutPercentage: 50 } }),
      );
    });
  });

  describe('delete', () => {
    it('throws NotFoundException when the flag does not exist', async () => {
      prisma.featureFlag.findUnique.mockResolvedValue(null);

      await expect(service.delete('missing')).rejects.toThrow(NotFoundException);
      expect(prisma.featureFlag.delete).not.toHaveBeenCalled();
    });

    it('deletes an existing flag', async () => {
      prisma.featureFlag.findUnique.mockResolvedValue({ key: 'existing' });

      await service.delete('existing');

      expect(prisma.featureFlag.delete).toHaveBeenCalledWith({ where: { key: 'existing' } });
    });
  });

  describe('resolveForUser', () => {
    it('resolves every registered key to its registry default with zero rows in the database', async () => {
      prisma.featureFlag.findMany.mockResolvedValue([]);

      const resolved = await service.resolveForUser('user-1');

      expect(resolved[AscendFeatureKey.LIVE_AI]).toBe(false);
      expect(resolved[AscendFeatureKey.RESEARCH_MODE]).toBe(false);
      expect(resolved[AscendFeatureKey.STORE_PURCHASES]).toBe(false);
      expect(resolved[AscendFeatureKey.ASCEND_PROMOTE]).toBe(false);
      expect(resolved[AscendFeatureKey.VISION_FORM_COACH]).toBe(false);
      expect(resolved[AscendFeatureKey.TRAINER_DASHBOARD]).toBe(true);
      expect(resolved[AscendFeatureKey.TRAINER_VERIFICATION]).toBe(true);
      expect(resolved[AscendFeatureKey.REMOTE_PUSH]).toBe(true);
      expect(resolved[AscendFeatureKey.GOOGLE_SIGN_IN]).toBe(true);
      expect(resolved[AscendFeatureKey.APPLE_SIGN_IN]).toBe(true);
      // No registered key is ever absent, unlike the old fail-open-by-omission contract.
      expect(Object.keys(resolved)).toHaveLength(Object.values(AscendFeatureKey).length);
    });

    it('a stored row overrides the registry default', async () => {
      prisma.featureFlag.findMany.mockResolvedValue([
        { key: AscendFeatureKey.LIVE_AI, enabled: true, rolloutPercentage: 100 },
      ]);

      const resolved = await service.resolveForUser('user-1');

      expect(resolved[AscendFeatureKey.LIVE_AI]).toBe(true);
    });

    it('resolves a disabled row override to false regardless of rollout percentage', async () => {
      prisma.featureFlag.findMany.mockResolvedValue([
        { key: 'off_flag', enabled: false, rolloutPercentage: 100 },
      ]);

      const resolved = await service.resolveForUser('user-1');

      expect(resolved.off_flag).toBe(false);
    });

    it('resolves an enabled ad-hoc flag at 0% rollout to false for any user', async () => {
      prisma.featureFlag.findMany.mockResolvedValue([
        { key: 'zero_flag', enabled: true, rolloutPercentage: 0 },
      ]);

      const resolved = await service.resolveForUser('any-user');

      expect(resolved.zero_flag).toBe(false);
    });

    it('is deterministic for the same (key, userId) pair at a partial rollout', async () => {
      prisma.featureFlag.findMany.mockResolvedValue([
        { key: 'partial_flag', enabled: true, rolloutPercentage: 50 },
      ]);

      const first = await service.resolveForUser('stable-user');
      const second = await service.resolveForUser('stable-user');

      expect(first).toEqual(second);
    });

    it('omits an ad-hoc key with no row at all — only registered keys are guaranteed present', async () => {
      prisma.featureFlag.findMany.mockResolvedValue([]);

      const resolved = await service.resolveForUser('user-1');

      expect(resolved.never_created).toBeUndefined();
    });
  });
});
