import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { RankingScope } from '@prisma/client';
import {
  ActivitySummary,
  computeActivitySummaries,
  computeActivitySummary,
} from '../../common/scoring/activity-scoring.util';
import { RankingCategory } from '../../common/scoring/ranking-category';
import { PrismaService } from '../../prisma/prisma.service';
import { RankingsService } from './rankings.service';

jest.mock('../../common/scoring/activity-scoring.util');
const mockedComputeActivitySummary = computeActivitySummary as jest.Mock;
const mockedComputeActivitySummaries = computeActivitySummaries as jest.Mock;

function summary(overrides: Partial<ActivitySummary> = {}): ActivitySummary {
  return {
    activeDays: 3,
    points: 4,
    strengthDays: 0,
    cardioDays: 0,
    nutritionDays: 0,
    verifiedCardioDays: 0,
    ...overrides,
  };
}

function season(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'season-1',
    label: 'August 2026',
    startsAt: new Date('2026-08-01T00:00:00Z'),
    endsAt: new Date('2026-09-01T00:00:00Z'),
    ...overrides,
  };
}

function optInRow(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    userId: 'user-1',
    scope: RankingScope.GLOBAL,
    localityCountry: null,
    localityRegion: null,
    localityCity: null,
    localityArea: null,
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
    mockedComputeActivitySummary.mockResolvedValue(summary());
    mockedComputeActivitySummaries.mockReset();
    mockedComputeActivitySummaries.mockImplementation(
      async (_prisma: unknown, userIds: string[]) => new Map(userIds.map((id) => [id, summary()])),
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
      prisma.rankingOptIn.upsert.mockResolvedValue(optInRow());

      await service.optIn('user-1', { scope: RankingScope.GLOBAL });

      expect(prisma.rankingOptIn.upsert).toHaveBeenCalledWith(
        expect.objectContaining({ where: { userId: 'user-1' } }),
      );
    });

    it('persists every locality field up through the chosen tier for a LOCAL opt-in', async () => {
      prisma.rankingOptIn.upsert.mockResolvedValue(
        optInRow({
          scope: RankingScope.LOCAL,
          localityCountry: 'Philippines',
          localityRegion: 'Metro Manila',
          localityCity: 'Quezon City',
          localityArea: 'Diliman',
        }),
      );

      await service.optIn('user-1', {
        scope: RankingScope.LOCAL,
        localityCountry: 'Philippines',
        localityRegion: 'Metro Manila',
        localityCity: 'Quezon City',
        localityArea: 'Diliman',
      });

      expect(prisma.rankingOptIn.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          update: {
            scope: RankingScope.LOCAL,
            localityCountry: 'Philippines',
            localityRegion: 'Metro Manila',
            localityCity: 'Quezon City',
            localityArea: 'Diliman',
          },
        }),
      );
    });

    it('clears every locality field when opting into a non-locality scope, ignoring stale input', async () => {
      prisma.rankingOptIn.upsert.mockResolvedValue(optInRow());

      await service.optIn('user-1', {
        scope: RankingScope.GLOBAL,
        // Stale fields from a previous LOCAL opt-in the caller forgot
        // to clear — the service must not persist them under GLOBAL.
        localityCountry: 'Philippines',
        localityCity: 'Quezon City',
      });

      expect(prisma.rankingOptIn.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          update: {
            scope: RankingScope.GLOBAL,
            localityCountry: null,
            localityRegion: null,
            localityCity: null,
            localityArea: null,
          },
        }),
      );
    });

    it('only persists localityCountry for a NATIONAL opt-in, not a supplied region/city', async () => {
      prisma.rankingOptIn.upsert.mockResolvedValue(
        optInRow({ scope: RankingScope.NATIONAL, localityCountry: 'Philippines' }),
      );

      await service.optIn('user-1', {
        scope: RankingScope.NATIONAL,
        localityCountry: 'Philippines',
        localityRegion: 'Metro Manila',
      });

      expect(prisma.rankingOptIn.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          update: {
            scope: RankingScope.NATIONAL,
            localityCountry: 'Philippines',
            localityRegion: null,
            localityCity: null,
            localityArea: null,
          },
        }),
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
      prisma.rankingOptIn.findUnique.mockResolvedValue(optInRow());

      const status = await service.getMyStatus('user-1');

      expect(status).toMatchObject({ optedIn: true, points: 4, activeDays: 3 });
    });

    it('includes the per-domain provenance breakdown alongside the blended score', async () => {
      prisma.rankingOptIn.findUnique.mockResolvedValue(optInRow());
      mockedComputeActivitySummary.mockResolvedValue(
        summary({ strengthDays: 2, cardioDays: 1, nutritionDays: 3, verifiedCardioDays: 1 }),
      );

      const status = await service.getMyStatus('user-1');

      expect(status).toMatchObject({
        strengthDays: 2,
        cardioDays: 1,
        nutritionDays: 3,
        verifiedCardioDays: 1,
      });
    });

    it('includes the full locality chain when opted in at the CITY tier', async () => {
      prisma.rankingOptIn.findUnique.mockResolvedValue(
        optInRow({
          scope: RankingScope.CITY,
          localityCountry: 'Philippines',
          localityRegion: 'Metro Manila',
          localityCity: 'Quezon City',
        }),
      );

      const status = await service.getMyStatus('user-1');

      expect(status).toMatchObject({
        scope: RankingScope.CITY,
        localityCountry: 'Philippines',
        localityRegion: 'Metro Manila',
        localityCity: 'Quezon City',
        localityArea: null,
      });
    });
  });

  describe('getLeaderboard', () => {
    it('rejects a viewer who has not opted in', async () => {
      prisma.rankingOptIn.findUnique.mockResolvedValue(null);

      await expect(
        service.getLeaderboard('user-1', RankingScope.GLOBAL, 1, 20),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('rejects a REGION request from a viewer who opted in with a broader (non-locality) scope', async () => {
      prisma.rankingOptIn.findUnique.mockResolvedValue(optInRow({ scope: RankingScope.GLOBAL }));

      await expect(
        service.getLeaderboard('user-1', RankingScope.REGION, 1, 20),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects viewing a narrower locality tier than the viewer opted into', async () => {
      prisma.rankingOptIn.findUnique.mockResolvedValue(
        optInRow({ scope: RankingScope.NATIONAL, localityCountry: 'Philippines' }),
      );

      await expect(
        service.getLeaderboard('user-1', RankingScope.LOCAL, 1, 20),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('GLOBAL scope includes every GLOBAL-scoped opted-in user', async () => {
      prisma.rankingOptIn.findUnique.mockResolvedValue(optInRow({ scope: RankingScope.GLOBAL }));
      prisma.rankingOptIn.findMany.mockResolvedValue([{ userId: 'user-1' }, { userId: 'user-2' }]);

      const result = await service.getLeaderboard('user-1', RankingScope.GLOBAL, 1, 20);

      expect(prisma.rankingOptIn.findMany).toHaveBeenCalledWith({
        where: { scope: RankingScope.GLOBAL },
        select: { userId: true },
      });
      expect(result.data).toHaveLength(2);
      expect(result.data[0].rank).toBe(1);
    });

    it('REGION scope matches on country+region, case-insensitively', async () => {
      prisma.rankingOptIn.findUnique.mockResolvedValue(
        optInRow({
          scope: RankingScope.REGION,
          localityCountry: 'Philippines',
          localityRegion: 'Metro Manila',
        }),
      );
      prisma.rankingOptIn.findMany.mockResolvedValue([{ userId: 'user-1' }, { userId: 'user-2' }]);

      const result = await service.getLeaderboard('user-1', RankingScope.REGION, 1, 20);

      expect(prisma.rankingOptIn.findMany).toHaveBeenCalledWith({
        where: {
          scope: RankingScope.REGION,
          localityCountry: { equals: 'Philippines', mode: 'insensitive' },
          localityRegion: { equals: 'Metro Manila', mode: 'insensitive' },
        },
        select: { userId: true },
      });
      expect(result.data).toHaveLength(2);
    });

    it('a LOCAL opt-in can also view the broader CITY leaderboard for the same place', async () => {
      prisma.rankingOptIn.findUnique.mockResolvedValue(
        optInRow({
          scope: RankingScope.LOCAL,
          localityCountry: 'Philippines',
          localityRegion: 'Metro Manila',
          localityCity: 'Quezon City',
          localityArea: 'Diliman',
        }),
      );
      prisma.rankingOptIn.findMany.mockResolvedValue([{ userId: 'user-1' }]);

      await service.getLeaderboard('user-1', RankingScope.CITY, 1, 20);

      expect(prisma.rankingOptIn.findMany).toHaveBeenCalledWith({
        where: {
          scope: RankingScope.CITY,
          localityCountry: { equals: 'Philippines', mode: 'insensitive' },
          localityRegion: { equals: 'Metro Manila', mode: 'insensitive' },
          localityCity: { equals: 'Quezon City', mode: 'insensitive' },
        },
        select: { userId: true },
      });
    });

    it('FRIENDS scope includes followed users who opted in, plus the viewer', async () => {
      prisma.rankingOptIn.findUnique.mockResolvedValue(optInRow({ scope: RankingScope.GLOBAL }));
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
      prisma.rankingOptIn.findUnique.mockResolvedValue(optInRow({ scope: RankingScope.GLOBAL }));
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

    it('defaults to OVERALL and sorts by the existing blended points, unchanged', async () => {
      prisma.rankingOptIn.findUnique.mockResolvedValue(optInRow({ scope: RankingScope.GLOBAL }));
      prisma.rankingOptIn.findMany.mockResolvedValue([{ userId: 'user-1' }, { userId: 'user-2' }]);
      mockedComputeActivitySummaries.mockResolvedValue(
        new Map([
          ['user-1', summary({ points: 2, strengthDays: 5 })],
          ['user-2', summary({ points: 6, strengthDays: 0 })],
        ]),
      );

      const result = await service.getLeaderboard('user-1', RankingScope.GLOBAL, 1, 20);

      expect(result.meta.category).toBe('OVERALL');
      expect(result.data.map((d) => d.userId)).toEqual(['user-2', 'user-1']);
    });

    it('a STRENGTH category request ranks by strengthDays instead of blended points', async () => {
      prisma.rankingOptIn.findUnique.mockResolvedValue(optInRow({ scope: RankingScope.GLOBAL }));
      prisma.rankingOptIn.findMany.mockResolvedValue([{ userId: 'user-1' }, { userId: 'user-2' }]);
      mockedComputeActivitySummaries.mockResolvedValue(
        new Map([
          // user-1 leads on blended points but trails on strengthDays —
          // a STRENGTH-category leaderboard must reorder around that.
          ['user-1', summary({ points: 6, strengthDays: 1 })],
          ['user-2', summary({ points: 2, strengthDays: 5 })],
        ]),
      );

      const result = await service.getLeaderboard(
        'user-1',
        RankingScope.GLOBAL,
        1,
        20,
        RankingCategory.STRENGTH,
      );

      expect(result.meta.category).toBe('STRENGTH');
      expect(result.data.map((d) => d.userId)).toEqual(['user-2', 'user-1']);
    });

    it('every entry always carries the full provenance breakdown, regardless of category', async () => {
      prisma.rankingOptIn.findUnique.mockResolvedValue(optInRow({ scope: RankingScope.GLOBAL }));
      prisma.rankingOptIn.findMany.mockResolvedValue([{ userId: 'user-1' }]);
      mockedComputeActivitySummaries.mockResolvedValue(
        new Map([
          [
            'user-1',
            summary({ strengthDays: 2, cardioDays: 3, nutritionDays: 1, verifiedCardioDays: 2 }),
          ],
        ]),
      );

      const result = await service.getLeaderboard(
        'user-1',
        RankingScope.GLOBAL,
        1,
        20,
        RankingCategory.CARDIO,
      );

      expect(result.data[0]).toMatchObject({
        strengthDays: 2,
        cardioDays: 3,
        nutritionDays: 1,
        verifiedCardioDays: 2,
      });
    });
  });
});
