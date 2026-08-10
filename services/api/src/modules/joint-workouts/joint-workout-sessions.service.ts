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
  TrainerGroupScheduledSessionRsvpStatus,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { FriendsService } from '../friends/friends.service';
import { TrainerGroupsService } from '../trainer-groups/trainer-groups.service';
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
 *
 * [create]'s `trainerGroupId` path (Build Session 10 Part 24) is the one
 * exception to the Friend requirement: TrainerGroupsService.
 * resolveGroupSessionInvitees vets the caller's permission and the
 * group's tier instead, since group membership is itself already an
 * opt-in, vetted relationship.
 */
@Injectable()
export class JointWorkoutSessionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly friendsService: FriendsService,
    private readonly trainerGroupsService: TrainerGroupsService,
  ) {}

  async create(hostId: string, dto: CreateJointWorkoutSessionDto) {
    if (dto.trainerGroupId && dto.inviteeIds?.length) {
      throw new BadRequestException('Provide either inviteeIds or trainerGroupId, not both.');
    }

    const inviteeIds = dto.trainerGroupId
      ? await this.trainerGroupsService.resolveGroupSessionInvitees(hostId, dto.trainerGroupId)
      : await this.resolveFriendInvitees(hostId, dto.inviteeIds);

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

  /**
   * Turns a `TrainerGroupScheduledSession` booking into a real live
   * session at meeting time (Build Session 13 continuation Part B) —
   * reuses [create]'s existing `trainerGroupId` path exactly as the
   * schema's own doc comment describes, rather than a second real-time
   * implementation. Idempotent: a second "Start" tap (e.g. a slow
   * network retry) returns the same already-created session instead of
   * spawning a duplicate one.
   */
  async startFromScheduledSession(hostId: string, scheduledSessionId: string) {
    const scheduled = await this.prisma.trainerGroupScheduledSession.findUnique({
      where: { id: scheduledSessionId },
    });
    if (!scheduled) throw new NotFoundException('Scheduled session not found.');
    if (scheduled.canceledAt) {
      throw new BadRequestException('This session was canceled.');
    }
    if (scheduled.jointWorkoutSessionId) {
      return this.getById(hostId, scheduled.jointWorkoutSessionId);
    }

    // resolveGroupSessionInvitees enforces the owner/moderator + expanded-
    // tier bar, the same one `cancelScheduledSession` and
    // `createScheduledSession` already apply to this booking.
    const session = await this.create(hostId, {
      trainerGroupId: scheduled.groupId,
      title: scheduled.title ?? undefined,
    });
    if (!session) throw new NotFoundException('Session not found.');

    await this.prisma.trainerGroupScheduledSession.update({
      where: { id: scheduledSessionId },
      data: { jointWorkoutSessionId: session.id },
    });

    return session;
  }

  /**
   * "Join session" for a scheduled booking (Build Session 13
   * continuation Part B) — restricted to members who actually RSVP'd
   * GOING (or the booking's own creator), not every group member who
   * happened to get auto-invited when [startFromScheduledSession]
   * reused the whole-group `trainerGroupId` invite path. Auto-accepts a
   * still-pending invite so tapping "Join" is one action instead of a
   * separate invite/accept/ready sequence.
   */
  async joinFromScheduledSession(userId: string, scheduledSessionId: string) {
    const scheduled = await this.prisma.trainerGroupScheduledSession.findUnique({
      where: { id: scheduledSessionId },
      include: { participants: { where: { userId } } },
    });
    if (!scheduled) throw new NotFoundException('Scheduled session not found.');
    if (!scheduled.jointWorkoutSessionId) {
      throw new BadRequestException('This session has not started yet.');
    }
    const isEligible =
      scheduled.createdById === userId ||
      scheduled.participants.some((p) => p.status === TrainerGroupScheduledSessionRsvpStatus.GOING);
    if (!isEligible) {
      throw new ForbiddenException('Only members who RSVP’d Going can join this session.');
    }

    const session = await this.getById(userId, scheduled.jointWorkoutSessionId);
    const participant = session?.participants.find((p) => p.userId === userId);
    if (participant?.status === JointWorkoutParticipantStatus.INVITED) {
      await this.acceptInvite(userId, scheduled.jointWorkoutSessionId);
      return this.getById(userId, scheduled.jointWorkoutSessionId);
    }
    return session;
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

  private async resolveFriendInvitees(hostId: string, rawInviteeIds?: string[]): Promise<string[]> {
    const inviteeIds = [...new Set(rawInviteeIds ?? [])].filter((id) => id !== hostId);
    for (const inviteeId of inviteeIds) {
      const isFriend = await this.friendsService.areFriends(hostId, inviteeId);
      if (!isFriend) throw new NotFoundException('User not found.');
    }
    return inviteeIds;
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
