import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { SportsService } from './sports.service';

function match(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'match-1',
    sportId: 'sport-1',
    createdById: 'user-1',
    status: 'INVITED',
    ...overrides,
  };
}

function participant(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'participant-1',
    matchId: 'match-1',
    userId: 'user-1',
    status: 'ACCEPTED',
    ...overrides,
  };
}

describe('SportsService', () => {
  let service: SportsService;
  let prisma: {
    sport: { findUnique: jest.Mock; findMany: jest.Mock; create: jest.Mock };
    user: { findUnique: jest.Mock };
    sportMatch: {
      findUnique: jest.Mock;
      findMany: jest.Mock;
      create: jest.Mock;
      update: jest.Mock;
      count: jest.Mock;
    };
    sportMatchParticipant: { findUnique: jest.Mock; findMany: jest.Mock; update: jest.Mock };
    sportScoreProposal: {
      findFirst: jest.Mock;
      create: jest.Mock;
      updateMany: jest.Mock;
      update: jest.Mock;
    };
    sportScoreConfirmation: { create: jest.Mock };
    sportMatchDispute: { create: jest.Mock };
    sportRating: { findUnique: jest.Mock; create: jest.Mock; update: jest.Mock };
    $transaction: jest.Mock;
  };

  beforeEach(async () => {
    prisma = {
      sport: {
        findUnique: jest
          .fn()
          .mockResolvedValue({ id: 'sport-1', code: 'BADMINTON', name: 'Badminton' }),
        findMany: jest.fn(),
        create: jest.fn(),
      },
      user: { findUnique: jest.fn().mockResolvedValue({ id: 'user-2' }) },
      sportMatch: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        count: jest.fn().mockResolvedValue(0),
      },
      sportMatchParticipant: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        update: jest.fn(),
      },
      sportScoreProposal: {
        findFirst: jest.fn(),
        create: jest.fn(),
        updateMany: jest.fn(),
        update: jest.fn(),
      },
      sportScoreConfirmation: { create: jest.fn() },
      sportMatchDispute: { create: jest.fn() },
      sportRating: {
        findUnique: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockImplementation(({ data }) =>
          Promise.resolve({
            id: `rating-${data.userId}`,
            userId: data.userId,
            sportId: data.sportId,
            rating: 1500,
            isProvisional: true,
            matchesPlayed: 0,
          }),
        ),
        update: jest.fn(),
      },
      $transaction: jest.fn((ops: unknown[]) => Promise.all(ops)),
    };

    const moduleRef = await Test.createTestingModule({
      providers: [SportsService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = moduleRef.get(SportsService);
    prisma.sportMatch.findUnique.mockResolvedValue(match());
    prisma.sportMatchParticipant.findUnique.mockResolvedValue(participant());
  });

  describe('listSports', () => {
    it('self-seeds every known SportCode, not just badminton (Build Session 12 Part 23-24)', async () => {
      prisma.sport.findMany.mockResolvedValue([
        { id: 'sport-1', code: 'BADMINTON', name: 'Badminton' },
        { id: 'sport-2', code: 'TABLE_TENNIS', name: 'Table Tennis' },
      ]);

      const sports = await service.listSports();

      const seededCodes = prisma.sport.findUnique.mock.calls.map(
        ([arg]: [{ where: { code: string } }]) => arg.where.code,
      );
      expect(seededCodes).toEqual(expect.arrayContaining(['BADMINTON', 'TABLE_TENNIS']));
      expect(sports.map((s) => s.code)).toEqual(
        expect.arrayContaining(['BADMINTON', 'TABLE_TENNIS']),
      );
    });
  });

  describe('createMatch', () => {
    it('rejects challenging yourself', async () => {
      await expect(
        service.createMatch('user-1', { sportCode: 'BADMINTON' as never, opponentId: 'user-1' }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('404s an opponent that does not exist', async () => {
      prisma.user.findUnique.mockResolvedValue(null);

      await expect(
        service.createMatch('user-1', { sportCode: 'BADMINTON' as never, opponentId: 'user-2' }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('creates an INVITED match with the creator already accepted', async () => {
      prisma.sportMatch.create.mockResolvedValue(match());

      await service.createMatch('user-1', {
        sportCode: 'BADMINTON' as never,
        opponentId: 'user-2',
      });

      expect(prisma.sportMatch.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            status: 'INVITED',
            participants: {
              create: [
                expect.objectContaining({ userId: 'user-1', status: 'ACCEPTED' }),
                expect.objectContaining({ userId: 'user-2', status: 'INVITED' }),
              ],
            },
          }),
        }),
      );
    });
  });

  describe('declineInvite', () => {
    it('cancels the whole match since there is no one left to play', async () => {
      prisma.sportMatchParticipant.findUnique.mockResolvedValue(
        participant({ userId: 'user-2', status: 'INVITED' }),
      );

      await service.declineInvite('user-2', 'match-1');

      expect(prisma.sportMatch.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ status: 'CANCELED' }) }),
      );
    });
  });

  describe('markReady / start', () => {
    it('rejects marking ready before accepting', async () => {
      prisma.sportMatchParticipant.findUnique.mockResolvedValue(participant({ status: 'INVITED' }));

      await expect(service.markReady('user-1', 'match-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('transitions the match to READY once both participants are ready', async () => {
      prisma.sportMatchParticipant.findUnique.mockResolvedValue(
        participant({ status: 'ACCEPTED' }),
      );
      prisma.sportMatchParticipant.findMany.mockResolvedValue([
        participant({ status: 'READY' }),
        participant({ id: 'p2', userId: 'user-2', status: 'READY' }),
      ]);

      await service.markReady('user-1', 'match-1');

      expect(prisma.sportMatch.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: { status: 'READY' } }),
      );
    });

    it('rejects starting before the match is READY', async () => {
      prisma.sportMatch.findUnique.mockResolvedValue(match({ status: 'INVITED' }));

      await expect(service.start('user-1', 'match-1')).rejects.toBeInstanceOf(BadRequestException);
    });

    it('starts a READY match', async () => {
      prisma.sportMatch.findUnique.mockResolvedValue(match({ status: 'READY' }));

      await service.start('user-1', 'match-1');

      expect(prisma.sportMatch.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ status: 'IN_PROGRESS' }) }),
      );
    });
  });

  describe('proposeScore / confirmScore / disputeScore', () => {
    it('rejects proposing a score outside IN_PROGRESS or DISPUTED', async () => {
      prisma.sportMatch.findUnique.mockResolvedValue(match({ status: 'READY' }));

      await expect(
        service.proposeScore('user-1', 'match-1', { proposerScore: 21, opponentScore: 15 }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('moves the match to SCORE_PENDING on a valid proposal', async () => {
      prisma.sportMatch.findUnique.mockResolvedValue(match({ status: 'IN_PROGRESS' }));

      await service.proposeScore('user-1', 'match-1', { proposerScore: 21, opponentScore: 15 });

      expect(prisma.sportMatch.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: { status: 'SCORE_PENDING' } }),
      );
    });

    it('rejects confirming your own proposed score', async () => {
      prisma.sportMatch.findUnique.mockResolvedValue(match({ status: 'SCORE_PENDING' }));
      prisma.sportScoreProposal.findFirst.mockResolvedValue({
        id: 'proposal-1',
        proposedById: 'user-1',
        proposerScore: 21,
        opponentScore: 15,
        matchId: 'match-1',
      });

      await expect(service.confirmScore('user-1', 'match-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('confirms a score, updates ratings, and marks the match CONFIRMED', async () => {
      prisma.sportMatch.findUnique.mockResolvedValue(
        match({ status: 'SCORE_PENDING', sportId: 'sport-1' }),
      );
      prisma.sportScoreProposal.findFirst.mockResolvedValue({
        id: 'proposal-1',
        proposedById: 'user-1',
        proposerScore: 21,
        opponentScore: 15,
        matchId: 'match-1',
      });
      prisma.sportMatchParticipant.findMany.mockResolvedValue([
        participant({ userId: 'user-1' }),
        participant({ id: 'p2', userId: 'user-2' }),
      ]);

      await service.confirmScore('user-2', 'match-1');

      expect(prisma.sportMatch.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ status: 'CONFIRMED' }) }),
      );
      expect(prisma.sportRating.update).toHaveBeenCalledTimes(2);
    });

    it('rejects disputing outside SCORE_PENDING', async () => {
      prisma.sportMatch.findUnique.mockResolvedValue(match({ status: 'IN_PROGRESS' }));

      await expect(service.disputeScore('user-1', 'match-1', 'unfair')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('moves a disputed match to DISPUTED', async () => {
      prisma.sportMatch.findUnique.mockResolvedValue(match({ status: 'SCORE_PENDING' }));

      await service.disputeScore('user-1', 'match-1', 'unfair');

      expect(prisma.sportMatchDispute.create).toHaveBeenCalled();
      expect(prisma.sportMatch.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: { status: 'DISPUTED' } }),
      );
    });
  });

  describe('cancel / voidMatch', () => {
    it('rejects canceling a match already in progress', async () => {
      prisma.sportMatch.findUnique.mockResolvedValue(match({ status: 'IN_PROGRESS' }));

      await expect(service.cancel('user-1', 'match-1')).rejects.toBeInstanceOf(BadRequestException);
    });

    it('cancels a match that has not started', async () => {
      prisma.sportMatch.findUnique.mockResolvedValue(match({ status: 'READY' }));

      await service.cancel('user-1', 'match-1');

      expect(prisma.sportMatch.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ status: 'CANCELED' }) }),
      );
    });

    it('rejects voiding a match that is not disputed', async () => {
      prisma.sportMatch.findUnique.mockResolvedValue(match({ status: 'IN_PROGRESS' }));

      await expect(service.voidMatch('user-1', 'match-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('voids a disputed match', async () => {
      prisma.sportMatch.findUnique.mockResolvedValue(match({ status: 'DISPUTED' }));

      await service.voidMatch('user-1', 'match-1');

      expect(prisma.sportMatch.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ status: 'VOID' }) }),
      );
    });
  });

  describe('getById', () => {
    it('404s for a real match the caller does not participate in', async () => {
      prisma.sportMatchParticipant.findUnique.mockResolvedValue(null);

      await expect(service.getById('someone-else', 'match-1')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });
});
