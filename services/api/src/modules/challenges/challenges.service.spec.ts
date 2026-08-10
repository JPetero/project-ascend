import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { computeActivitySummaries } from '../../common/scoring/activity-scoring.util';
import { PrismaService } from '../../prisma/prisma.service';
import { ChallengesService } from './challenges.service';

jest.mock('../../common/scoring/activity-scoring.util');
const mockedComputeActivitySummaries = computeActivitySummaries as jest.Mock;

function challenge(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'challenge-1',
    creatorId: 'creator-1',
    title: 'August step-up',
    description: null,
    startsAt: new Date('2026-08-01T00:00:00Z'),
    endsAt: new Date('2026-08-31T00:00:00Z'),
    ...overrides,
  };
}

describe('ChallengesService', () => {
  let service: ChallengesService;
  let prisma: {
    challenge: {
      create: jest.Mock;
      findMany: jest.Mock;
      findUnique: jest.Mock;
      count: jest.Mock;
      delete: jest.Mock;
    };
    challengeParticipant: {
      create: jest.Mock;
      findMany: jest.Mock;
      findUnique: jest.Mock;
      deleteMany: jest.Mock;
    };
    communityProfile: { findMany: jest.Mock };
  };

  beforeEach(async () => {
    mockedComputeActivitySummaries.mockReset();
    mockedComputeActivitySummaries.mockImplementation(
      async (_prisma: unknown, userIds: string[]) =>
        new Map(userIds.map((id) => [id, { activeDays: 2, points: 2 }])),
    );

    prisma = {
      challenge: {
        create: jest.fn(),
        findMany: jest.fn(),
        findUnique: jest.fn(),
        count: jest.fn(),
        delete: jest.fn(),
      },
      challengeParticipant: {
        create: jest.fn(),
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn(),
        deleteMany: jest.fn(),
      },
      communityProfile: { findMany: jest.fn().mockResolvedValue([]) },
    };

    const moduleRef = await Test.createTestingModule({
      providers: [ChallengesService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = moduleRef.get(ChallengesService);
  });

  describe('create', () => {
    it('rejects an endsAt that is not after startsAt', async () => {
      await expect(
        service.create('user-1', {
          title: 'Bad window',
          startsAt: '2026-08-10T00:00:00Z',
          endsAt: '2026-08-01T00:00:00Z',
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(prisma.challenge.create).not.toHaveBeenCalled();
    });

    it('creates the challenge with the creator auto-joined as a participant', async () => {
      prisma.challenge.create.mockResolvedValue(challenge({ creatorId: 'user-1' }));

      await service.create('user-1', {
        title: 'August step-up',
        startsAt: '2026-08-01T00:00:00Z',
        endsAt: '2026-08-31T00:00:00Z',
      });

      expect(prisma.challenge.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            creatorId: 'user-1',
            participants: { create: { userId: 'user-1' } },
          }),
        }),
      );
    });
  });

  describe('join', () => {
    it('rejects joining a challenge that has already ended', async () => {
      prisma.challenge.findUnique.mockResolvedValue(
        challenge({ endsAt: new Date('2020-01-01T00:00:00Z') }),
      );

      await expect(service.join('user-1', 'challenge-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
      expect(prisma.challengeParticipant.create).not.toHaveBeenCalled();
    });

    it('is a no-op if already joined', async () => {
      prisma.challenge.findUnique.mockResolvedValue(challenge());
      prisma.challengeParticipant.findUnique.mockResolvedValue({ id: 'p-1' });

      await service.join('user-1', 'challenge-1');

      expect(prisma.challengeParticipant.create).not.toHaveBeenCalled();
    });

    it('joins when the challenge is open and the user has not yet joined', async () => {
      prisma.challenge.findUnique.mockResolvedValue(challenge());
      prisma.challengeParticipant.findUnique.mockResolvedValue(null);

      await service.join('user-1', 'challenge-1');

      expect(prisma.challengeParticipant.create).toHaveBeenCalledWith({
        data: { challengeId: 'challenge-1', userId: 'user-1' },
      });
    });

    it('rejects joining a challenge that does not exist', async () => {
      prisma.challenge.findUnique.mockResolvedValue(null);

      await expect(service.join('user-1', 'missing')).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  describe('delete', () => {
    it('rejects a non-creator deleting the challenge', async () => {
      prisma.challenge.findUnique.mockResolvedValue(challenge({ creatorId: 'creator-1' }));

      await expect(service.delete('someone-else', 'challenge-1')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
      expect(prisma.challenge.delete).not.toHaveBeenCalled();
    });

    it('allows the creator to delete it', async () => {
      prisma.challenge.findUnique.mockResolvedValue(challenge({ creatorId: 'creator-1' }));

      await service.delete('creator-1', 'challenge-1');

      expect(prisma.challenge.delete).toHaveBeenCalledWith({ where: { id: 'challenge-1' } });
    });
  });

  describe('getById', () => {
    it('hides per-participant progress from a non-participant', async () => {
      prisma.challenge.findUnique.mockResolvedValue(challenge());
      prisma.challengeParticipant.findMany.mockResolvedValue([
        { userId: 'creator-1', joinedAt: new Date() },
      ]);

      const result = await service.getById('bystander', 'challenge-1');

      expect(result.isParticipant).toBe(false);
      expect(result.participants).toBeNull();
      expect(mockedComputeActivitySummaries).not.toHaveBeenCalled();
    });

    it('includes per-participant progress for a participant', async () => {
      prisma.challenge.findUnique.mockResolvedValue(challenge());
      prisma.challengeParticipant.findMany.mockResolvedValue([
        { userId: 'creator-1', joinedAt: new Date() },
      ]);

      const result = await service.getById('creator-1', 'challenge-1');

      expect(result.isParticipant).toBe(true);
      expect(result.participants).toHaveLength(1);
      expect(result.participants![0]).toMatchObject({ userId: 'creator-1', activeDays: 2 });
    });
  });
});
