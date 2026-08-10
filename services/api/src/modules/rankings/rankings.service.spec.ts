import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { RankingScope } from '@prisma/client';
import {
  computeActivitySummaries,
  computeActivitySummary,
} from '../../common/scoring/activity-scoring.util';
import { PrismaService } from '../../prisma/prisma.service';
import { RankingsService } from './rankings.service';

jest.mock('../../common/scoring/activity-scoring.util');
const mockedComputeActivitySummary = computeActivitySummary as jest.Mock;
const mockedComputeActivitySummaries = computeActivitySummaries as jest.Mock;

function season(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'season-1',
    label: 'August 2026',
    startsAt: new Date('2026-08-01T00:00:00Z'),
    endsAt: new Date('2026-09-01T00:00:00Z'),
    ...overrides,
  };
}

describe('RankingsService', () => {
  let service: RankingsService;
  let prisma: {
    rankingOptIn: {
      upsert: jest.Mock;
      deleteMany: jest.Mock;
      findUnique: jest.Mock;
      findMany: jest.Mock;
    };
    rankingSeason: { findFirst: jest.Mock; create: jest.Mock };
    communityFollow: { findMany: jest.Mock };
    communityProfile: { findMany: jest.Mock };
  };

  beforeEach(async () => {
    mockedComputeActivitySummary.mockReset();
    mockedComputeActivitySummary.mockResolvedValue({ activeDays: 3, points: 4 });
    mockedComputeActivitySummaries.mockReset();
    mockedComputeActivitySummaries.mockImplementation(
      async (_prisma: unknown, userIds: string[]) =>
        new Map(userIds.map((id) => [id, { activeDays: 3, points: 4 }])),
    );

    prisma = {
      rankingOptIn: {
        upsert: jest.fn(),
        deleteMany: jest.fn(),
        findUnique: jest.fn(),
        findMany: jest.fn(),
      },
      rankingSeason: { findFirst: jest.fn(), create: jest.fn() },
      communityFollow: { findMany: jest.fn() },
      communityProfile: { findMany: jest.fn().mockResolvedValue([]) },
    };
    prisma.rankingSeason.findFirst.mockResolvedValue(season());

    const moduleRef = await Test.createTestingModule({
      providers: [RankingsService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = moduleRef.get(RankingsService);
  });

  describe('optIn', () => {
    it('upserts keyed on userId', async () => {
      prisma.rankingOptIn.upsert.mockResolvedValue({
        userId: 'user-1',
        scope: RankingScope.GLOBAL,
        regionLabel: null,
      });

      await service.optIn('user-1', { scope: RankingScope.GLOBAL });

      expect(prisma.rankingOptIn.upsert).toHaveBeenCalledWith(
        expect.objectContaining({ where: { userId: 'user-1' } }),
      );
    });
  });

  describe('optOut', () => {
    it('deletes any existing opt-in row', async () => {
      await service.optOut('user-1');

      expect(prisma.rankingOptIn.deleteMany).toHaveBeenCalledWith({ where: { userId: 'user-1' } });
    });
  });

  describe('getMyStatus', () => {
    it('reports not opted in when there is no row, without computing a score', async () => {
      prisma.rankingOptIn.findUnique.mockResolvedValue(null);

      const status = await service.getMyStatus('user-1');

      expect(status).toEqual({ optedIn: false });
      expect(mockedComputeActivitySummary).not.toHaveBeenCalled();
    });

    it('includes the season score when opted in', async () => {
      prisma.rankingOptIn.findUnique.mockResolvedValue({
        userId: 'user-1',
        scope: RankingScope.GLOBAL,
        regionLabel: null,
      });

      const status = await service.getMyStatus('user-1');

      expect(status).toMatchObject({ optedIn: true, points: 4, activeDays: 3 });
    });
  });

  describe('getLeaderboard', () => {
    it('rejects a viewer who has not opted in', async () => {
      prisma.rankingOptIn.findUnique.mockResolvedValue(null);

      await expect(
        service.getLeaderboard('user-1', RankingScope.GLOBAL, 1, 20),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('rejects a REGION request from a viewer who opted in with a different scope', async () => {
      prisma.rankingOptIn.findUnique.mockResolvedValue({
        userId: 'user-1',
        scope: RankingScope.GLOBAL,
        regionLabel: null,
      });

      await expect(
        service.getLeaderboard('user-1', RankingScope.REGION, 1, 20),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('GLOBAL scope includes every GLOBAL-scoped opted-in user', async () => {
      prisma.rankingOptIn.findUnique.mockResolvedValue({
        userId: 'user-1',
        scope: RankingScope.GLOBAL,
        regionLabel: null,
      });
      prisma.rankingOptIn.findMany.mockResolvedValue([{ userId: 'user-1' }, { userId: 'user-2' }]);

      const result = await service.getLeaderboard('user-1', RankingScope.GLOBAL, 1, 20);

      expect(prisma.rankingOptIn.findMany).toHaveBeenCalledWith({
        where: { scope: RankingScope.GLOBAL },
        select: { userId: true },
      });
      expect(result.data).toHaveLength(2);
      expect(result.data[0].rank).toBe(1);
    });

    it('FRIENDS scope includes followed users who opted in, plus the viewer', async () => {
      prisma.rankingOptIn.findUnique.mockResolvedValue({
        userId: 'user-1',
        scope: RankingScope.GLOBAL,
        regionLabel: null,
      });
      prisma.communityFollow.findMany.mockResolvedValue([{ followingId: 'user-2' }]);
      prisma.rankingOptIn.findMany.mockResolvedValue([{ userId: 'user-1' }, { userId: 'user-2' }]);

      const result = await service.getLeaderboard('user-1', RankingScope.FRIENDS, 1, 20);

      expect(prisma.communityFollow.findMany).toHaveBeenCalledWith({
        where: { followerId: 'user-1' },
        select: { followingId: true },
      });
      expect(result.data.map((d) => d.userId)).toEqual(
        expect.arrayContaining(['user-1', 'user-2']),
      );
    });

    it('paginates the already-sorted candidate list', async () => {
      prisma.rankingOptIn.findUnique.mockResolvedValue({
        userId: 'user-1',
        scope: RankingScope.GLOBAL,
        regionLabel: null,
      });
      prisma.rankingOptIn.findMany.mockResolvedValue([
        { userId: 'user-1' },
        { userId: 'user-2' },
        { userId: 'user-3' },
      ]);

      const result = await service.getLeaderboard('user-1', RankingScope.GLOBAL, 2, 1);

      expect(result.data).toHaveLength(1);
      expect(result.data[0].rank).toBe(2);
      expect(result.meta.total).toBe(3);
    });
  });
});
