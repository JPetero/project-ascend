import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { FriendsService } from '../friends/friends.service';
import { TrainerGroupsService } from '../trainer-groups/trainer-groups.service';
import { JointWorkoutSessionsService } from './joint-workout-sessions.service';

function session(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'session-1',
    hostId: 'host-1',
    status: 'CREATED',
    ...overrides,
  };
}

function participant(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'participant-1',
    sessionId: 'session-1',
    userId: 'host-1',
    status: 'ACCEPTED',
    ...overrides,
  };
}

describe('JointWorkoutSessionsService', () => {
  let service: JointWorkoutSessionsService;
  let prisma: {
    jointWorkoutSession: {
      findUnique: jest.Mock;
      findMany: jest.Mock;
      create: jest.Mock;
      update: jest.Mock;
    };
    jointWorkoutParticipant: {
      findUnique: jest.Mock;
      findMany: jest.Mock;
      create: jest.Mock;
      update: jest.Mock;
      updateMany: jest.Mock;
      count: jest.Mock;
    };
    jointWorkoutSharedResult: { create: jest.Mock };
    jointWorkoutEvent: { create: jest.Mock };
    $transaction: jest.Mock;
  };
  let friendsService: { areFriends: jest.Mock };
  let trainerGroupsService: { resolveGroupSessionInvitees: jest.Mock };

  beforeEach(async () => {
    prisma = {
      jointWorkoutSession: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      jointWorkoutParticipant: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
        count: jest.fn(),
      },
      jointWorkoutSharedResult: { create: jest.fn() },
      jointWorkoutEvent: { create: jest.fn().mockResolvedValue({}) },
      $transaction: jest.fn((ops: unknown[]) => Promise.all(ops)),
    };
    friendsService = { areFriends: jest.fn().mockResolvedValue(true) };
    trainerGroupsService = { resolveGroupSessionInvitees: jest.fn() };

    const moduleRef = await Test.createTestingModule({
      providers: [
        JointWorkoutSessionsService,
        { provide: PrismaService, useValue: prisma },
        { provide: FriendsService, useValue: friendsService },
        { provide: TrainerGroupsService, useValue: trainerGroupsService },
      ],
    }).compile();

    service = moduleRef.get(JointWorkoutSessionsService);

    // getById is called at the end of several flows — give it a safe default.
    prisma.jointWorkoutParticipant.findUnique.mockResolvedValue(participant());
    prisma.jointWorkoutSession.findUnique.mockResolvedValue(session());
  });

  describe('create', () => {
    it('404s when an invitee is not a friend', async () => {
      friendsService.areFriends.mockResolvedValue(false);

      await expect(service.create('host-1', { inviteeIds: ['stranger-1'] })).rejects.toBeInstanceOf(
        NotFoundException,
      );
      expect(prisma.jointWorkoutSession.create).not.toHaveBeenCalled();
    });

    it('creates the host as ACCEPTED and friends as INVITED', async () => {
      prisma.jointWorkoutSession.create.mockResolvedValue(session());

      await service.create('host-1', { inviteeIds: ['friend-1'] });

      expect(prisma.jointWorkoutSession.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            hostId: 'host-1',
            participants: {
              create: [
                expect.objectContaining({ userId: 'host-1', status: 'ACCEPTED' }),
                expect.objectContaining({ userId: 'friend-1', status: 'INVITED' }),
              ],
            },
          }),
        }),
      );
    });

    it('rejects passing both inviteeIds and trainerGroupId', async () => {
      await expect(
        service.create('host-1', { inviteeIds: ['friend-1'], trainerGroupId: 'group-1' }),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(trainerGroupsService.resolveGroupSessionInvitees).not.toHaveBeenCalled();
      expect(friendsService.areFriends).not.toHaveBeenCalled();
    });

    it(
      'resolves invitees from the trainer group instead of the Friend graph when ' +
        'trainerGroupId is set (Build Session 10 Part 24)',
      async () => {
        trainerGroupsService.resolveGroupSessionInvitees.mockResolvedValue([
          'member-1',
          'member-2',
        ]);
        prisma.jointWorkoutSession.create.mockResolvedValue(session());

        await service.create('host-1', { trainerGroupId: 'group-1' });

        expect(trainerGroupsService.resolveGroupSessionInvitees).toHaveBeenCalledWith(
          'host-1',
          'group-1',
        );
        expect(friendsService.areFriends).not.toHaveBeenCalled();
        expect(prisma.jointWorkoutSession.create).toHaveBeenCalledWith(
          expect.objectContaining({
            data: expect.objectContaining({
              participants: {
                create: [
                  expect.objectContaining({ userId: 'host-1', status: 'ACCEPTED' }),
                  expect.objectContaining({ userId: 'member-1', status: 'INVITED' }),
                  expect.objectContaining({ userId: 'member-2', status: 'INVITED' }),
                ],
              },
            }),
          }),
        );
      },
    );

    it('propagates a permission error from resolveGroupSessionInvitees', async () => {
      trainerGroupsService.resolveGroupSessionInvitees.mockRejectedValue(
        new ForbiddenException('nope'),
      );

      await expect(service.create('host-1', { trainerGroupId: 'group-1' })).rejects.toBeInstanceOf(
        ForbiddenException,
      );
      expect(prisma.jointWorkoutSession.create).not.toHaveBeenCalled();
    });
  });

  describe('invite', () => {
    it('403s a non-host caller', async () => {
      await expect(service.invite('someone-else', 'session-1', 'friend-1')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });

    it('rejects inviting once the session has started', async () => {
      prisma.jointWorkoutSession.findUnique.mockResolvedValue(session({ status: 'IN_PROGRESS' }));

      await expect(service.invite('host-1', 'session-1', 'friend-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('404s a non-friend invitee', async () => {
      friendsService.areFriends.mockResolvedValue(false);

      await expect(service.invite('host-1', 'session-1', 'stranger-1')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('re-invites someone who previously declined', async () => {
      prisma.jointWorkoutParticipant.findUnique.mockResolvedValue(
        participant({ userId: 'friend-1', status: 'DECLINED' }),
      );
      prisma.jointWorkoutParticipant.update.mockResolvedValue(
        participant({ userId: 'friend-1', status: 'INVITED' }),
      );

      const result = await service.invite('host-1', 'session-1', 'friend-1');

      expect(result.status).toBe('INVITED');
    });
  });

  describe('acceptInvite / declineInvite', () => {
    it('rejects accepting when not currently invited', async () => {
      prisma.jointWorkoutParticipant.findUnique.mockResolvedValue(
        participant({ status: 'ACCEPTED' }),
      );

      await expect(service.acceptInvite('friend-1', 'session-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('accepts a pending invite', async () => {
      prisma.jointWorkoutParticipant.findUnique.mockResolvedValue(
        participant({ userId: 'friend-1', status: 'INVITED' }),
      );
      prisma.jointWorkoutParticipant.update.mockResolvedValue(
        participant({ userId: 'friend-1', status: 'ACCEPTED' }),
      );

      const result = await service.acceptInvite('friend-1', 'session-1');

      expect(result.status).toBe('ACCEPTED');
    });

    it('declines a pending invite', async () => {
      prisma.jointWorkoutParticipant.findUnique.mockResolvedValue(
        participant({ userId: 'friend-1', status: 'INVITED' }),
      );
      prisma.jointWorkoutParticipant.update.mockResolvedValue(
        participant({ userId: 'friend-1', status: 'DECLINED' }),
      );

      const result = await service.declineInvite('friend-1', 'session-1');

      expect(result.status).toBe('DECLINED');
    });
  });

  describe('markReady', () => {
    it('rejects marking ready before accepting', async () => {
      prisma.jointWorkoutParticipant.findUnique.mockResolvedValue(
        participant({ status: 'INVITED' }),
      );

      await expect(service.markReady('friend-1', 'session-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('marks an accepted participant ready', async () => {
      prisma.jointWorkoutParticipant.findUnique.mockResolvedValue(
        participant({ status: 'ACCEPTED' }),
      );
      prisma.jointWorkoutParticipant.update.mockResolvedValue(participant({ status: 'READY' }));

      const result = await service.markReady('host-1', 'session-1');

      expect(result.status).toBe('READY');
    });
  });

  describe('start', () => {
    it('403s a non-host caller', async () => {
      await expect(service.start('someone-else', 'session-1')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });

    it('rejects starting before the host is ready', async () => {
      prisma.jointWorkoutParticipant.findMany.mockResolvedValue([
        participant({ status: 'ACCEPTED' }),
      ]);

      await expect(service.start('host-1', 'session-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('rejects starting with no other ready participant', async () => {
      prisma.jointWorkoutParticipant.findMany.mockResolvedValue([participant({ status: 'READY' })]);

      await expect(service.start('host-1', 'session-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('starts the session once at least two participants are ready', async () => {
      prisma.jointWorkoutParticipant.findMany.mockResolvedValue([
        participant({ status: 'READY' }),
        participant({ id: 'participant-2', userId: 'friend-1', status: 'READY' }),
      ]);

      await service.start('host-1', 'session-1');

      expect(prisma.$transaction).toHaveBeenCalled();
      expect(prisma.jointWorkoutParticipant.updateMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { sessionId: 'session-1', status: 'READY' },
          data: { status: 'ACTIVE' },
        }),
      );
    });
  });

  describe('submitProgress', () => {
    it('rejects progress on a session that has not started', async () => {
      await expect(
        service.submitProgress('host-1', 'session-1', { exerciseName: 'Squat' }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects progress from a non-active participant', async () => {
      prisma.jointWorkoutSession.findUnique.mockResolvedValue(session({ status: 'IN_PROGRESS' }));
      prisma.jointWorkoutParticipant.findUnique.mockResolvedValue(
        participant({ status: 'ACCEPTED' }),
      );

      await expect(
        service.submitProgress('host-1', 'session-1', { exerciseName: 'Squat' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('records a shared result for an active participant', async () => {
      prisma.jointWorkoutSession.findUnique.mockResolvedValue(session({ status: 'IN_PROGRESS' }));
      prisma.jointWorkoutParticipant.findUnique.mockResolvedValue(
        participant({ status: 'ACTIVE' }),
      );
      prisma.jointWorkoutSharedResult.create.mockResolvedValue({ id: 'result-1' });

      const result = await service.submitProgress('host-1', 'session-1', {
        exerciseName: 'Squat',
        setsCompleted: 3,
      });

      expect(result.id).toBe('result-1');
      expect(prisma.jointWorkoutSharedResult.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ exerciseName: 'Squat', setsCompleted: 3 }),
        }),
      );
    });
  });

  describe('finish', () => {
    it('finishes the session once no participant remains active', async () => {
      prisma.jointWorkoutSession.findUnique.mockResolvedValue(session({ status: 'IN_PROGRESS' }));
      prisma.jointWorkoutParticipant.findUnique.mockResolvedValue(
        participant({ status: 'ACTIVE' }),
      );
      prisma.jointWorkoutParticipant.count.mockResolvedValue(0);

      await service.finish('host-1', 'session-1');

      expect(prisma.jointWorkoutSession.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ status: 'FINISHED' }) }),
      );
    });

    it('leaves the session in progress while another participant is still active', async () => {
      prisma.jointWorkoutSession.findUnique.mockResolvedValue(session({ status: 'IN_PROGRESS' }));
      prisma.jointWorkoutParticipant.findUnique.mockResolvedValue(
        participant({ status: 'ACTIVE' }),
      );
      prisma.jointWorkoutParticipant.count.mockResolvedValue(1);

      await service.finish('host-1', 'session-1');

      expect(prisma.jointWorkoutSession.update).not.toHaveBeenCalled();
    });
  });

  describe('leave', () => {
    it('cancels the whole session when the host leaves', async () => {
      prisma.jointWorkoutSession.findUnique.mockResolvedValue(session({ status: 'CREATED' }));
      prisma.jointWorkoutParticipant.findUnique.mockResolvedValue(
        participant({ userId: 'host-1', status: 'ACCEPTED' }),
      );

      await service.leave('host-1', 'session-1');

      expect(prisma.jointWorkoutSession.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ status: 'CANCELED' }) }),
      );
    });

    it('does not cancel the session when a non-host participant leaves', async () => {
      prisma.jointWorkoutSession.findUnique.mockResolvedValue(session({ status: 'IN_PROGRESS' }));
      prisma.jointWorkoutParticipant.findUnique.mockResolvedValue(
        participant({ userId: 'friend-1', status: 'ACTIVE' }),
      );
      prisma.jointWorkoutParticipant.count.mockResolvedValue(1);

      await service.leave('friend-1', 'session-1');

      expect(prisma.jointWorkoutSession.update).not.toHaveBeenCalled();
    });
  });

  describe('cancel', () => {
    it('403s a non-host caller', async () => {
      await expect(service.cancel('someone-else', 'session-1')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });

    it('rejects canceling an already-finished session', async () => {
      prisma.jointWorkoutSession.findUnique.mockResolvedValue(session({ status: 'FINISHED' }));

      await expect(service.cancel('host-1', 'session-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('cancels an in-progress session', async () => {
      await service.cancel('host-1', 'session-1');

      expect(prisma.jointWorkoutSession.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ status: 'CANCELED' }) }),
      );
    });
  });

  describe('getById', () => {
    it('404s for a real session the caller does not participate in', async () => {
      prisma.jointWorkoutParticipant.findUnique.mockResolvedValue(null);

      await expect(service.getById('someone-else', 'session-1')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });
});
