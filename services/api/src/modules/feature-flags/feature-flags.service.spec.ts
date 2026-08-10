import { NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
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
        findMany: jest.fn(),
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
    it('returns every flag ordered by key', async () => {
      prisma.featureFlag.findMany.mockResolvedValue([{ key: 'a' }]);

      const result = await service.listAll();

      expect(result).toEqual([{ key: 'a' }]);
      expect(prisma.featureFlag.findMany).toHaveBeenCalledWith({ orderBy: { key: 'asc' } });
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
    it('resolves a disabled flag to false regardless of rollout percentage', async () => {
      prisma.featureFlag.findMany.mockResolvedValue([
        { key: 'off_flag', enabled: false, rolloutPercentage: 100 },
      ]);

      const resolved = await service.resolveForUser('user-1');

      expect(resolved).toEqual({ off_flag: false });
    });

    it('resolves an enabled flag at 100% rollout to true for any user', async () => {
      prisma.featureFlag.findMany.mockResolvedValue([
        { key: 'full_flag', enabled: true, rolloutPercentage: 100 },
      ]);

      const resolved = await service.resolveForUser('any-user');

      expect(resolved).toEqual({ full_flag: true });
    });

    it('resolves an enabled flag at 0% rollout to false for any user', async () => {
      prisma.featureFlag.findMany.mockResolvedValue([
        { key: 'zero_flag', enabled: true, rolloutPercentage: 0 },
      ]);

      const resolved = await service.resolveForUser('any-user');

      expect(resolved).toEqual({ zero_flag: false });
    });

    it('is deterministic for the same (key, userId) pair at a partial rollout', async () => {
      prisma.featureFlag.findMany.mockResolvedValue([
        { key: 'partial_flag', enabled: true, rolloutPercentage: 50 },
      ]);

      const first = await service.resolveForUser('stable-user');
      const second = await service.resolveForUser('stable-user');

      expect(first).toEqual(second);
    });

    it('omits keys for which no FeatureFlag row exists', async () => {
      prisma.featureFlag.findMany.mockResolvedValue([]);

      const resolved = await service.resolveForUser('user-1');

      expect(resolved).toEqual({});
    });
  });
});
