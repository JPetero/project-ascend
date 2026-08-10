import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import {
  SportCode,
  SportMatchParticipantStatus,
  SportMatchStatus,
  SportScoreProposalStatus,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateSportMatchDto } from './dto/create-sport-match.dto';
import { ProposeScoreDto } from './dto/propose-score.dto';

const SPORT_NAMES: Record<SportCode, string> = {
  [SportCode.BADMINTON]: 'Badminton',
  [SportCode.TABLE_TENNIS]: 'Table Tennis',
};

/** Cancelable states — before play has actually started. */
const OPEN_STATUSES: SportMatchStatus[] = [
  SportMatchStatus.CREATED,
  SportMatchStatus.INVITED,
  SportMatchStatus.READY,
];

/** Ratings converge faster for new players — see SportRating's schema comment. */
const PROVISIONAL_MATCH_THRESHOLD = 5;
const PROVISIONAL_K_FACTOR = 40;
const ESTABLISHED_K_FACTOR = 20;

/** Only ever sets a flag for later review — see this module's schema-level doc comment on why this never bans or blocks anyone. */
const COLLUSION_LOOKBACK_MS = 60 * 60 * 1000;
const COLLUSION_MATCH_THRESHOLD = 3;

/**
 * Sports match system (Build Session 8 Part 10) — 1v1 matches with a
 * dual-confirmation score flow. A proposed score only counts once the
 * *other* participant confirms it (see confirmScore); a disagreement
 * raises a dispute instead of silently trusting either side.
 */
@Injectable()
export class SportsService {
  constructor(private readonly prisma: PrismaService) {}

  async listSports() {
    // Build Session 12 Part 23-24 — self-seeds every known SportCode
    // (not just badminton anymore) the first time anyone asks, same
    // lazy-create pattern this already used for badminton alone.
    await Promise.all(Object.values(SportCode).map((code) => this.getOrCreateSport(code)));
    return this.prisma.sport.findMany({ orderBy: { name: 'asc' } });
  }

  async createMatch(creatorId: string, dto: CreateSportMatchDto) {
    if (creatorId === dto.opponentId) {
      throw new BadRequestException('You cannot challenge yourself.');
    }
    const opponent = await this.prisma.user.findUnique({ where: { id: dto.opponentId } });
    if (!opponent) throw new NotFoundException('User not found.');

    const sport = await this.getOrCreateSport(dto.sportCode);

    const match = await this.prisma.sportMatch.create({
      data: {
        sportId: sport.id,
        ruleSetId: dto.ruleSetId,
        createdById: creatorId,
        status: SportMatchStatus.INVITED,
        participants: {
          create: [
            {
              userId: creatorId,
              status: SportMatchParticipantStatus.ACCEPTED,
              respondedAt: new Date(),
            },
            { userId: dto.opponentId, status: SportMatchParticipantStatus.INVITED },
          ],
        },
      },
    });
    return this.getById(creatorId, match.id);
  }

  async acceptInvite(userId: string, matchId: string) {
    const participant = await this.requireParticipant(matchId, userId);
    if (participant.status !== SportMatchParticipantStatus.INVITED) {
      throw new BadRequestException('This challenge is no longer pending.');
    }
    await this.prisma.sportMatchParticipant.update({
      where: { id: participant.id },
      data: { status: SportMatchParticipantStatus.ACCEPTED, respondedAt: new Date() },
    });
    return this.getById(userId, matchId);
  }

  async declineInvite(userId: string, matchId: string) {
    const participant = await this.requireParticipant(matchId, userId);
    if (participant.status !== SportMatchParticipantStatus.INVITED) {
      throw new BadRequestException('This challenge is no longer pending.');
    }
    await this.prisma.$transaction([
      this.prisma.sportMatchParticipant.update({
        where: { id: participant.id },
        data: { status: SportMatchParticipantStatus.DECLINED, respondedAt: new Date() },
      }),
      // A declined 1v1 challenge has no one left to play, so it ends here
      // rather than lingering as an unfillable match.
      this.prisma.sportMatch.update({
        where: { id: matchId },
        data: { status: SportMatchStatus.CANCELED, canceledAt: new Date() },
      }),
    ]);
    return this.getById(userId, matchId);
  }

  async markReady(userId: string, matchId: string) {
    const participant = await this.requireParticipant(matchId, userId);
    if (participant.status !== SportMatchParticipantStatus.ACCEPTED) {
      throw new BadRequestException('Accept the challenge before marking yourself ready.');
    }
    await this.prisma.sportMatchParticipant.update({
      where: { id: participant.id },
      data: { status: SportMatchParticipantStatus.READY, readyAt: new Date() },
    });

    const participants = await this.prisma.sportMatchParticipant.findMany({ where: { matchId } });
    const bothReady = participants.every((p) => p.status === SportMatchParticipantStatus.READY);
    if (bothReady) {
      await this.prisma.sportMatch.update({
        where: { id: matchId },
        data: { status: SportMatchStatus.READY },
      });
    }
    return this.getById(userId, matchId);
  }

  async start(userId: string, matchId: string) {
    await this.requireParticipant(matchId, userId);
    const match = await this.requireMatch(matchId);
    if (match.status !== SportMatchStatus.READY) {
      throw new BadRequestException('Both players must be ready before starting.');
    }
    await this.prisma.sportMatch.update({
      where: { id: matchId },
      data: { status: SportMatchStatus.IN_PROGRESS, startedAt: new Date() },
    });
    return this.getById(userId, matchId);
  }

  async proposeScore(userId: string, matchId: string, dto: ProposeScoreDto) {
    await this.requireParticipant(matchId, userId);
    const match = await this.requireMatch(matchId);
    if (
      match.status !== SportMatchStatus.IN_PROGRESS &&
      match.status !== SportMatchStatus.DISPUTED
    ) {
      throw new BadRequestException('This match is not awaiting a score.');
    }

    await this.prisma.$transaction([
      this.prisma.sportScoreProposal.updateMany({
        where: { matchId, status: SportScoreProposalStatus.PENDING },
        data: { status: SportScoreProposalStatus.SUPERSEDED },
      }),
      this.prisma.sportScoreProposal.create({
        data: {
          matchId,
          proposedById: userId,
          proposerScore: dto.proposerScore,
          opponentScore: dto.opponentScore,
        },
      }),
      this.prisma.sportMatch.update({
        where: { id: matchId },
        data: { status: SportMatchStatus.SCORE_PENDING },
      }),
    ]);
    return this.getById(userId, matchId);
  }

  async confirmScore(userId: string, matchId: string) {
    await this.requireParticipant(matchId, userId);
    const match = await this.requireMatch(matchId);
    if (match.status !== SportMatchStatus.SCORE_PENDING) {
      throw new BadRequestException('There is no score awaiting confirmation.');
    }

    const proposal = await this.prisma.sportScoreProposal.findFirst({
      where: { matchId, status: SportScoreProposalStatus.PENDING },
      orderBy: { createdAt: 'desc' },
    });
    if (!proposal) throw new NotFoundException('No pending score proposal found.');
    if (proposal.proposedById === userId) {
      throw new BadRequestException('You cannot confirm your own proposed score.');
    }

    await this.prisma.$transaction([
      this.prisma.sportScoreConfirmation.create({
        data: { proposalId: proposal.id, confirmedById: userId },
      }),
      this.prisma.sportScoreProposal.update({
        where: { id: proposal.id },
        data: { status: SportScoreProposalStatus.CONFIRMED },
      }),
      this.prisma.sportMatch.update({
        where: { id: matchId },
        data: { status: SportMatchStatus.CONFIRMED, confirmedAt: new Date() },
      }),
    ]);

    await this.applyRatings(match.sportId, proposal);
    return this.getById(userId, matchId);
  }

  async disputeScore(userId: string, matchId: string, reason: string) {
    await this.requireParticipant(matchId, userId);
    const match = await this.requireMatch(matchId);
    if (match.status !== SportMatchStatus.SCORE_PENDING) {
      throw new BadRequestException('There is no score to dispute.');
    }

    await this.prisma.$transaction([
      this.prisma.sportMatchDispute.create({
        data: { matchId, raisedById: userId, reason },
      }),
      this.prisma.sportMatch.update({
        where: { id: matchId },
        data: { status: SportMatchStatus.DISPUTED },
      }),
    ]);
    return this.getById(userId, matchId);
  }

  async cancel(userId: string, matchId: string) {
    await this.requireParticipant(matchId, userId);
    const match = await this.requireMatch(matchId);
    if (!OPEN_STATUSES.includes(match.status)) {
      throw new BadRequestException('This match can no longer be canceled.');
    }
    await this.prisma.sportMatch.update({
      where: { id: matchId },
      data: { status: SportMatchStatus.CANCELED, canceledAt: new Date() },
    });
    return this.getById(userId, matchId);
  }

  /** Either participant can void a disputed match rather than requiring staff intervention this session — see this module's schema-level doc comment. */
  async voidMatch(userId: string, matchId: string) {
    await this.requireParticipant(matchId, userId);
    const match = await this.requireMatch(matchId);
    if (match.status !== SportMatchStatus.DISPUTED) {
      throw new BadRequestException('Only a disputed match can be voided.');
    }
    await this.prisma.sportMatch.update({
      where: { id: matchId },
      data: { status: SportMatchStatus.VOID, voidedAt: new Date() },
    });
    return this.getById(userId, matchId);
  }

  async listMine(userId: string) {
    return this.prisma.sportMatch.findMany({
      where: { participants: { some: { userId } } },
      include: { participants: true, sport: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getById(userId: string, matchId: string) {
    await this.requireParticipant(matchId, userId);
    return this.prisma.sportMatch.findUnique({
      where: { id: matchId },
      include: {
        sport: true,
        participants: true,
        scoreProposals: { orderBy: { createdAt: 'desc' } },
        disputes: { orderBy: { createdAt: 'desc' } },
      },
    });
  }

  async getMyRating(userId: string, sportCode: SportCode) {
    const sport = await this.getOrCreateSport(sportCode);
    const rating = await this.prisma.sportRating.findUnique({
      where: { userId_sportId: { userId, sportId: sport.id } },
    });
    // No row yet means the player hasn't finished a rated match — the
    // same "absence of a row is the default" pattern RankingOptIn uses.
    return (
      rating ?? { userId, sportId: sport.id, rating: 1500, isProvisional: true, matchesPlayed: 0 }
    );
  }

  async leaderboard(sportCode: SportCode, limit = 50) {
    const sport = await this.getOrCreateSport(sportCode);
    const ratings = await this.prisma.sportRating.findMany({
      where: { sportId: sport.id },
      orderBy: { rating: 'desc' },
      take: Math.min(limit, 100),
      include: { user: { include: { communityProfile: true } } },
    });
    return ratings.map((r) => ({
      userId: r.userId,
      displayName: r.user.communityProfile?.displayName ?? 'Ascend member',
      rating: r.rating,
      isProvisional: r.isProvisional,
      matchesPlayed: r.matchesPlayed,
    }));
  }

  private async applyRatings(
    sportId: string,
    proposal: {
      proposedById: string;
      proposerScore: number;
      opponentScore: number;
      matchId: string;
    },
  ) {
    const participants = await this.prisma.sportMatchParticipant.findMany({
      where: { matchId: proposal.matchId },
    });
    const opponentParticipant = participants.find((p) => p.userId !== proposal.proposedById);
    if (!opponentParticipant) return;
    const opponentId = opponentParticipant.userId;

    const [proposerRating, opponentRating] = await Promise.all([
      this.getOrCreateRating(proposal.proposedById, sportId),
      this.getOrCreateRating(opponentId, sportId),
    ]);

    const expectedProposer =
      1 / (1 + 10 ** ((opponentRating.rating - proposerRating.rating) / 400));
    const expectedOpponent = 1 - expectedProposer;

    const actualProposer =
      proposal.proposerScore === proposal.opponentScore
        ? 0.5
        : proposal.proposerScore > proposal.opponentScore
          ? 1
          : 0;
    const actualOpponent = 1 - actualProposer;

    const kProposer = proposerRating.isProvisional ? PROVISIONAL_K_FACTOR : ESTABLISHED_K_FACTOR;
    const kOpponent = opponentRating.isProvisional ? PROVISIONAL_K_FACTOR : ESTABLISHED_K_FACTOR;

    await this.prisma.$transaction([
      this.prisma.sportRating.update({
        where: { id: proposerRating.id },
        data: {
          rating: proposerRating.rating + kProposer * (actualProposer - expectedProposer),
          matchesPlayed: { increment: 1 },
          isProvisional: proposerRating.matchesPlayed + 1 < PROVISIONAL_MATCH_THRESHOLD,
        },
      }),
      this.prisma.sportRating.update({
        where: { id: opponentRating.id },
        data: {
          rating: opponentRating.rating + kOpponent * (actualOpponent - expectedOpponent),
          matchesPlayed: { increment: 1 },
          isProvisional: opponentRating.matchesPlayed + 1 < PROVISIONAL_MATCH_THRESHOLD,
        },
      }),
    ]);

    await this.flagIfSuspiciousFrequency(
      sportId,
      proposal.matchId,
      proposal.proposedById,
      opponentId,
    );
  }

  private async flagIfSuspiciousFrequency(
    sportId: string,
    matchId: string,
    userIdA: string,
    userIdB: string,
  ): Promise<void> {
    const since = new Date(Date.now() - COLLUSION_LOOKBACK_MS);
    const recentCount = await this.prisma.sportMatch.count({
      where: {
        sportId,
        status: SportMatchStatus.CONFIRMED,
        confirmedAt: { gte: since },
        AND: [
          { participants: { some: { userId: userIdA } } },
          { participants: { some: { userId: userIdB } } },
        ],
      },
    });
    if (recentCount > COLLUSION_MATCH_THRESHOLD) {
      await this.prisma.sportMatch.update({
        where: { id: matchId },
        data: {
          flagged: true,
          flagReason:
            'This pair has confirmed an unusually high number of matches against each other recently.',
        },
      });
    }
  }

  private async getOrCreateRating(userId: string, sportId: string) {
    const existing = await this.prisma.sportRating.findUnique({
      where: { userId_sportId: { userId, sportId } },
    });
    if (existing) return existing;
    return this.prisma.sportRating.create({ data: { userId, sportId } });
  }

  private async getOrCreateSport(code: SportCode) {
    const existing = await this.prisma.sport.findUnique({ where: { code } });
    if (existing) return existing;
    return this.prisma.sport.create({ data: { code, name: SPORT_NAMES[code] } });
  }

  private async requireMatch(matchId: string) {
    const match = await this.prisma.sportMatch.findUnique({ where: { id: matchId } });
    if (!match) throw new NotFoundException('Match not found.');
    return match;
  }

  private async requireParticipant(matchId: string, userId: string) {
    const participant = await this.prisma.sportMatchParticipant.findUnique({
      where: { matchId_userId: { matchId, userId } },
    });
    if (!participant) throw new NotFoundException('Match not found.');
    return participant;
  }
}
