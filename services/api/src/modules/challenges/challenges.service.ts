import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Challenge } from '@prisma/client';
import { computeActivitySummary } from '../../common/scoring/activity-scoring.util';
import { paginationArgs, paginationMeta } from '../../common/pagination/pagination-query.dto';
import { PaginationQueryDto } from '../../common/pagination/pagination-query.dto';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateChallengeDto } from './dto/create-challenge.dto';

const MS_PER_DAY = 24 * 60 * 60 * 1000;

/**
 * Time-boxed, join-by-choice challenges — Founder Scenario 21's
 * Rankings/Challenges MVP. Progress is measured the same non-gameable
 * "active days" way as Rankings (see activity-scoring.util.ts), never by
 * a raw-volume metric, so a challenge can't be won by one dangerous,
 * oversized session.
 */
@Injectable()
export class ChallengesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, dto: CreateChallengeDto) {
    const startsAt = new Date(dto.startsAt);
    const endsAt = new Date(dto.endsAt);
    if (endsAt <= startsAt) {
      throw new BadRequestException('endsAt must be after startsAt.');
    }

    const challenge = await this.prisma.challenge.create({
      data: {
        creatorId: userId,
        title: dto.title,
        description: dto.description,
        startsAt,
        endsAt,
        participants: { create: { userId } },
      },
    });
    return this.serializeSummary(challenge, 1);
  }

  async listMine(userId: string) {
    const participations = await this.prisma.challengeParticipant.findMany({
      where: { userId },
      select: { challengeId: true },
    });
    const challenges = await this.prisma.challenge.findMany({
      where: { id: { in: participations.map((p) => p.challengeId) } },
      orderBy: { startsAt: 'desc' },
      include: { _count: { select: { participants: true } } },
    });
    return challenges.map((c) => this.serializeSummary(c, c._count.participants));
  }

  async listDiscoverable(userId: string, query: PaginationQueryDto) {
    const joined = await this.prisma.challengeParticipant.findMany({
      where: { userId },
      select: { challengeId: true },
    });
    const where = {
      endsAt: { gt: new Date() },
      id: { notIn: joined.map((j) => j.challengeId) },
    };
    const [challenges, total] = await Promise.all([
      this.prisma.challenge.findMany({
        where,
        orderBy: { startsAt: 'desc' },
        include: { _count: { select: { participants: true } } },
        ...paginationArgs(query),
      }),
      this.prisma.challenge.count({ where }),
    ]);
    return {
      data: challenges.map((c) => this.serializeSummary(c, c._count.participants)),
      meta: paginationMeta(query, total),
    };
  }

  async getById(userId: string, id: string) {
    const challenge = await this.findChallenge(id);
    const participants = await this.prisma.challengeParticipant.findMany({
      where: { challengeId: id },
      orderBy: { joinedAt: 'asc' },
    });
    const isParticipant = participants.some((p) => p.userId === userId);

    const summary = this.serializeSummary(challenge, participants.length);
    if (!isParticipant) {
      return { ...summary, isParticipant: false, participants: null };
    }

    const now = new Date();
    const progressTo = now < challenge.endsAt ? now : challenge.endsAt;
    const totalDays = Math.max(
      1,
      Math.ceil((progressTo.getTime() - challenge.startsAt.getTime()) / MS_PER_DAY) + 1,
    );

    const profiles = await this.prisma.communityProfile.findMany({
      where: { userId: { in: participants.map((p) => p.userId) } },
      select: { userId: true, displayName: true, avatarUrl: true },
    });
    const profileByUser = new Map(profiles.map((p) => [p.userId, p]));

    const withProgress = await Promise.all(
      participants.map(async (participant) => {
        const activitySummary = await computeActivitySummary(
          this.prisma,
          participant.userId,
          challenge.startsAt,
          progressTo,
        );
        return {
          userId: participant.userId,
          displayName: profileByUser.get(participant.userId)?.displayName ?? null,
          avatarUrl: profileByUser.get(participant.userId)?.avatarUrl ?? null,
          activeDays: activitySummary.activeDays,
          totalDays,
        };
      }),
    );

    return { ...summary, isParticipant: true, participants: withProgress };
  }

  async join(userId: string, id: string): Promise<void> {
    const challenge = await this.findChallenge(id);
    if (challenge.endsAt <= new Date()) {
      throw new BadRequestException('This challenge has already ended.');
    }
    const existing = await this.prisma.challengeParticipant.findUnique({
      where: { challengeId_userId: { challengeId: id, userId } },
    });
    if (existing) return;
    await this.prisma.challengeParticipant.create({ data: { challengeId: id, userId } });
  }

  async leave(userId: string, id: string): Promise<void> {
    await this.prisma.challengeParticipant.deleteMany({ where: { challengeId: id, userId } });
  }

  async delete(userId: string, id: string): Promise<void> {
    const challenge = await this.findChallenge(id);
    if (challenge.creatorId !== userId) {
      throw new ForbiddenException('Only the creator can delete this challenge.');
    }
    await this.prisma.challenge.delete({ where: { id } });
  }

  private async findChallenge(id: string): Promise<Challenge> {
    const challenge = await this.prisma.challenge.findUnique({ where: { id } });
    if (!challenge) throw new NotFoundException('Challenge not found.');
    return challenge;
  }

  private serializeSummary(challenge: Challenge, participantCount: number) {
    return {
      id: challenge.id,
      creatorId: challenge.creatorId,
      title: challenge.title,
      description: challenge.description,
      startsAt: challenge.startsAt,
      endsAt: challenge.endsAt,
      participantCount,
    };
  }
}
