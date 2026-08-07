import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  JointWorkoutEventType,
  JointWorkoutParticipantStatus,
  JointWorkoutSessionStatus,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { FriendsService } from '../friends/friends.service';
import { CreateJointWorkoutSessionDto } from './dto/create-joint-workout-session.dto';
import { SubmitJointWorkoutProgressDto } from './dto/submit-joint-workout-progress.dto';

/**
 * Friend-only joint workout sessions (Build Session 8 Part 9). Every
 * participant — including invitees added after creation via [invite] —
 * must already be a Friend of the host (FriendsService.areFriends);
 * strangers are never reachable, and a non-friend invite 404s rather
 * than 403s (the same not-found-over-forbidden pattern Friends and
 * Messages already use). Health data (weight, BMI, heart rate,
 * nutrition, wearable metrics) is never read or written here — only the
 * whitelisted fields on JointWorkoutSharedResult.
 */
@Injectable()
export class JointWorkoutSessionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly friendsService: FriendsService,
  ) {}

  async create(hostId: string, dto: CreateJointWorkoutSessionDto) {
    const inviteeIds = [...new Set(dto.inviteeIds ?? [])].filter((id) => id !== hostId);

    for (const inviteeId of inviteeIds) {
      const isFriend = await this.friendsService.areFriends(hostId, inviteeId);
      if (!isFriend) throw new NotFoundException('User not found.');
    }

    const session = await this.prisma.jointWorkoutSession.create({
      data: {
        hostId,
        title: dto.title,
        participants: {
          create: [
            {
              userId: hostId,
              status: JointWorkoutParticipantStatus.ACCEPTED,
              respondedAt: new Date(),
            },
            ...inviteeIds.map((userId) => ({
              userId,
              status: JointWorkoutParticipantStatus.INVITED,
            })),
          ],
        },
      },
    });

    await Promise.all(
      inviteeIds.map((userId) => this.logEvent(session.id, userId, JointWorkoutEventType.INVITED)),
    );

    return this.getById(hostId, session.id);
  }

  async invite(hostId: string, sessionId: string, inviteeId: string) {
    const session = await this.requireSession(sessionId);
    if (session.hostId !== hostId) {
      throw new ForbiddenException('Only the host can invite people to this session.');
    }
    if (session.status !== JointWorkoutSessionStatus.CREATED) {
      throw new BadRequestException('This session has already started.');
    }
    if (inviteeId === hostId) {
      throw new BadRequestException('You cannot invite yourself.');
    }

    const isFriend = await this.friendsService.areFriends(hostId, inviteeId);
    if (!isFriend) throw new NotFoundException('User not found.');

    const existing = await this.prisma.jointWorkoutParticipant.findUnique({
      where: { sessionId_userId: { sessionId, userId: inviteeId } },
    });
    if (
      existing &&
      existing.status !== JointWorkoutParticipantStatus.DECLINED &&
      existing.status !== JointWorkoutParticipantStatus.LEFT
    ) {
      throw new BadRequestException('This person has already been invited.');
    }

    const participant = existing
      ? await this.prisma.jointWorkoutParticipant.update({
          where: { id: existing.id },
          data: {
            status: JointWorkoutParticipantStatus.INVITED,
            respondedAt: null,
            readyAt: null,
            leftAt: null,
          },
        })
      : await this.prisma.jointWorkoutParticipant.create({
          data: { sessionId, userId: inviteeId, status: JointWorkoutParticipantStatus.INVITED },
        });

    await this.logEvent(sessionId, inviteeId, JointWorkoutEventType.INVITED);
    return participant;
  }

  async acceptInvite(userId: string, sessionId: string) {
    const participant = await this.requireParticipant(sessionId, userId);
    if (participant.status !== JointWorkoutParticipantStatus.INVITED) {
      throw new BadRequestException('This invite is no longer pending.');
    }
    const updated = await this.prisma.jointWorkoutParticipant.update({
      where: { id: participant.id },
      data: { status: JointWorkoutParticipantStatus.ACCEPTED, respondedAt: new Date() },
    });
    await this.logEvent(sessionId, userId, JointWorkoutEventType.ACCEPTED);
    return updated;
  }

  async declineInvite(userId: string, sessionId: string) {
    const participant = await this.requireParticipant(sessionId, userId);
    if (participant.status !== JointWorkoutParticipantStatus.INVITED) {
      throw new BadRequestException('This invite is no longer pending.');
    }
    const updated = await this.prisma.jointWorkoutParticipant.update({
      where: { id: participant.id },
      data: { status: JointWorkoutParticipantStatus.DECLINED, respondedAt: new Date() },
    });
    await this.logEvent(sessionId, userId, JointWorkoutEventType.DECLINED);
    return updated;
  }

  async markReady(userId: string, sessionId: string) {
    const participant = await this.requireParticipant(sessionId, userId);
    if (participant.status !== JointWorkoutParticipantStatus.ACCEPTED) {
      throw new BadRequestException('Accept the invite before marking yourself ready.');
    }
    const updated = await this.prisma.jointWorkoutParticipant.update({
      where: { id: participant.id },
      data: { status: JointWorkoutParticipantStatus.READY, readyAt: new Date() },
    });
    await this.logEvent(sessionId, userId, JointWorkoutEventType.READY);
    return updated;
  }

  /** No forced identical loads — starting only requires everyone who's joining to be READY, never that they chose the same weights or exercises. */
  async start(hostId: string, sessionId: string) {
    const session = await this.requireSession(sessionId);
    if (session.hostId !== hostId) {
      throw new ForbiddenException('Only the host can start this session.');
    }
    if (session.status !== JointWorkoutSessionStatus.CREATED) {
      throw new BadRequestException('This session cannot be started.');
    }

    const participants = await this.prisma.jointWorkoutParticipant.findMany({
      where: { sessionId },
    });
    const host = participants.find((p) => p.userId === hostId);
    if (!host || host.status !== JointWorkoutParticipantStatus.READY) {
      throw new BadRequestException('Mark yourself ready before starting.');
    }
    const readyCount = participants.filter(
      (p) => p.status === JointWorkoutParticipantStatus.READY,
    ).length;
    if (readyCount < 2) {
      throw new BadRequestException('At least one other participant must be ready.');
    }

    await this.prisma.$transaction([
      this.prisma.jointWorkoutSession.update({
        where: { id: sessionId },
        data: { status: JointWorkoutSessionStatus.IN_PROGRESS, startedAt: new Date() },
      }),
      this.prisma.jointWorkoutParticipant.updateMany({
        where: { sessionId, status: JointWorkoutParticipantStatus.READY },
        data: { status: JointWorkoutParticipantStatus.ACTIVE },
      }),
    ]);
    await this.logEvent(sessionId, hostId, JointWorkoutEventType.STARTED);
    return this.getById(hostId, sessionId);
  }

  async submitProgress(userId: string, sessionId: string, dto: SubmitJointWorkoutProgressDto) {
    const session = await this.requireSession(sessionId);
    if (session.status !== JointWorkoutSessionStatus.IN_PROGRESS) {
      throw new BadRequestException('This session is not in progress.');
    }
    const participant = await this.requireParticipant(sessionId, userId);
    if (participant.status !== JointWorkoutParticipantStatus.ACTIVE) {
      throw new ForbiddenException('You are not an active participant in this session.');
    }

    const result = await this.prisma.jointWorkoutSharedResult.create({
      data: {
        participantId: participant.id,
        exerciseName: dto.exerciseName,
        setsCompleted: dto.setsCompleted,
        durationSeconds: dto.durationSeconds,
        distanceMeters: dto.distanceMeters,
        isPersonalRecord: dto.isPersonalRecord ?? false,
      },
    });

    const summary = dto.exerciseName
      ? `${dto.exerciseName}${dto.setsCompleted != null ? ` — ${dto.setsCompleted} sets` : ''}`
      : undefined;
    await this.logEvent(sessionId, userId, JointWorkoutEventType.PROGRESS, summary);
    return result;
  }

  async finish(userId: string, sessionId: string) {
    const session = await this.requireSession(sessionId);
    const participant = await this.requireParticipant(sessionId, userId);
    if (participant.status !== JointWorkoutParticipantStatus.ACTIVE) {
      throw new BadRequestException('You are not an active participant in this session.');
    }

    await this.prisma.jointWorkoutParticipant.update({
      where: { id: participant.id },
      data: { status: JointWorkoutParticipantStatus.FINISHED, finishedAt: new Date() },
    });
    await this.logEvent(sessionId, userId, JointWorkoutEventType.FINISHED);

    if (session.status === JointWorkoutSessionStatus.IN_PROGRESS) {
      await this.finishSessionIfNoneActive(sessionId);
    }
    return this.getById(userId, sessionId);
  }

  async leave(userId: string, sessionId: string) {
    const session = await this.requireSession(sessionId);
    const participant = await this.requireParticipant(sessionId, userId);
    const alreadyDone: JointWorkoutParticipantStatus[] = [
      JointWorkoutParticipantStatus.FINISHED,
      JointWorkoutParticipantStatus.DECLINED,
      JointWorkoutParticipantStatus.LEFT,
    ];
    if (alreadyDone.includes(participant.status)) {
      throw new BadRequestException('You are no longer part of this session.');
    }

    await this.prisma.jointWorkoutParticipant.update({
      where: { id: participant.id },
      data: { status: JointWorkoutParticipantStatus.LEFT, leftAt: new Date() },
    });
    await this.logEvent(sessionId, userId, JointWorkoutEventType.LEFT);

    if (userId === session.hostId && session.status !== JointWorkoutSessionStatus.FINISHED) {
      // A joint session needs its host — the host leaving cancels it for
      // everyone rather than orphaning the session.
      await this.cancelInternal(sessionId);
      await this.logEvent(sessionId, userId, JointWorkoutEventType.CANCELED);
    } else if (session.status === JointWorkoutSessionStatus.IN_PROGRESS) {
      await this.finishSessionIfNoneActive(sessionId);
    }
  }

  async cancel(hostId: string, sessionId: string) {
    const session = await this.requireSession(sessionId);
    if (session.hostId !== hostId) {
      throw new ForbiddenException('Only the host can cancel this session.');
    }
    if (
      session.status === JointWorkoutSessionStatus.FINISHED ||
      session.status === JointWorkoutSessionStatus.CANCELED
    ) {
      throw new BadRequestException('This session has already ended.');
    }
    await this.cancelInternal(sessionId);
    await this.logEvent(sessionId, hostId, JointWorkoutEventType.CANCELED);
  }

  async listMine(userId: string) {
    return this.prisma.jointWorkoutSession.findMany({
      where: { participants: { some: { userId } } },
      include: { participants: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getById(userId: string, sessionId: string) {
    await this.requireParticipant(sessionId, userId);
    return this.prisma.jointWorkoutSession.findUnique({
      where: { id: sessionId },
      include: {
        participants: { include: { results: true } },
        events: { orderBy: { createdAt: 'desc' }, take: 50 },
      },
    });
  }

  private async finishSessionIfNoneActive(sessionId: string): Promise<void> {
    const remainingActive = await this.prisma.jointWorkoutParticipant.count({
      where: { sessionId, status: JointWorkoutParticipantStatus.ACTIVE },
    });
    if (remainingActive === 0) {
      await this.prisma.jointWorkoutSession.update({
        where: { id: sessionId },
        data: { status: JointWorkoutSessionStatus.FINISHED, finishedAt: new Date() },
      });
    }
  }

  private async cancelInternal(sessionId: string): Promise<void> {
    await this.prisma.jointWorkoutSession.update({
      where: { id: sessionId },
      data: { status: JointWorkoutSessionStatus.CANCELED, canceledAt: new Date() },
    });
  }

  private async requireSession(sessionId: string) {
    const session = await this.prisma.jointWorkoutSession.findUnique({ where: { id: sessionId } });
    if (!session) throw new NotFoundException('Session not found.');
    return session;
  }

  private async requireParticipant(sessionId: string, userId: string) {
    const participant = await this.prisma.jointWorkoutParticipant.findUnique({
      where: { sessionId_userId: { sessionId, userId } },
    });
    if (!participant) throw new NotFoundException('Session not found.');
    return participant;
  }

  private async logEvent(
    sessionId: string,
    userId: string | null,
    type: JointWorkoutEventType,
    message?: string,
  ): Promise<void> {
    await this.prisma.jointWorkoutEvent.create({ data: { sessionId, userId, type, message } });
  }
}
