import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import {
  TrainerGroupInvitationStatus,
  TrainerGroupMemberRole,
  TrainerGroupScheduledSessionRsvpStatus,
  WorkoutAssignmentStatus,
} from '@prisma/client';
import { CapabilityService } from '../../common/entitlements/capability.service';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { TrainerGroupsService } from './trainer-groups.service';

function group(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'group-1',
    ownerId: 'owner-1',
    name: 'Strong Squad',
    description: null,
    ...overrides,
  };
}

function invitation(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'invite-1',
    groupId: 'group-1',
    inviterId: 'owner-1',
    inviteeId: 'invitee-1',
    status: TrainerGroupInvitationStatus.PENDING,
    createdAt: new Date(),
    ...overrides,
  };
}

describe('TrainerGroupsService', () => {
  let service: TrainerGroupsService;
  let capabilityService: { hasCapabilityForUser: jest.Mock; hasCapabilityForUsers: jest.Mock };
  let prisma: {
    trainerGroup: {
      count: jest.Mock;
      create: jest.Mock;
      findUnique: jest.Mock;
      findUniqueOrThrow: jest.Mock;
      findMany: jest.Mock;
      delete: jest.Mock;
    };
    trainerGroupMember: {
      count: jest.Mock;
      findUnique: jest.Mock;
      findMany: jest.Mock;
      create: jest.Mock;
      update: jest.Mock;
      delete: jest.Mock;
    };
    trainerGroupInvitation: {
      upsert: jest.Mock;
      findUnique: jest.Mock;
      update: jest.Mock;
      findMany: jest.Mock;
    };
    trainerGroupMessage: { create: jest.Mock };
    trainerGroupSharedPlan: { findUnique: jest.Mock; delete: jest.Mock; upsert: jest.Mock };
    trainerGroupAnnouncement: { create: jest.Mock; findMany: jest.Mock };
    workoutPlan: { findUnique: jest.Mock; create: jest.Mock };
    workoutPlanExercise: { createMany: jest.Mock };
    workoutAssignment: {
      create: jest.Mock;
      findUnique: jest.Mock;
      findMany: jest.Mock;
      update: jest.Mock;
      updateMany: jest.Mock;
      delete: jest.Mock;
      groupBy: jest.Mock;
    };
    trainerGroupScheduledSession: {
      create: jest.Mock;
      findUnique: jest.Mock;
      findMany: jest.Mock;
      update: jest.Mock;
    };
    trainerGroupScheduledSessionParticipant: {
      findUnique: jest.Mock;
      count: jest.Mock;
      upsert: jest.Mock;
      deleteMany: jest.Mock;
      groupBy: jest.Mock;
      findMany: jest.Mock;
    };
    communityBlock: { findUnique: jest.Mock };
    $transaction: jest.Mock;
  };
  let notifications: { notify: jest.Mock };

  beforeEach(async () => {
    prisma = {
      trainerGroup: {
        count: jest.fn(),
        create: jest.fn(),
        findUnique: jest.fn(),
        findUniqueOrThrow: jest.fn(),
        findMany: jest.fn(),
        delete: jest.fn(),
      },
      trainerGroupMember: {
        count: jest.fn(),
        findUnique: jest.fn(),
        findMany: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
      },
      trainerGroupInvitation: {
        upsert: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
        findMany: jest.fn(),
      },
      trainerGroupMessage: { create: jest.fn() },
      trainerGroupSharedPlan: { findUnique: jest.fn(), delete: jest.fn(), upsert: jest.fn() },
      trainerGroupAnnouncement: { create: jest.fn(), findMany: jest.fn() },
      workoutPlan: { findUnique: jest.fn(), create: jest.fn() },
      workoutPlanExercise: { createMany: jest.fn() },
      workoutAssignment: {
        create: jest.fn(),
        findUnique: jest.fn(),
        findMany: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
        delete: jest.fn(),
        groupBy: jest.fn().mockResolvedValue([]),
      },
      trainerGroupScheduledSession: {
        create: jest.fn(),
        findUnique: jest.fn(),
        findMany: jest.fn(),
        update: jest.fn(),
      },
      trainerGroupScheduledSessionParticipant: {
        findUnique: jest.fn(),
        count: jest.fn().mockResolvedValue(0),
        upsert: jest.fn(),
        deleteMany: jest.fn(),
        groupBy: jest.fn().mockResolvedValue([]),
        findMany: jest.fn().mockResolvedValue([]),
      },
      communityBlock: { findUnique: jest.fn().mockResolvedValue(null) },
      $transaction: jest.fn((arg: unknown) => {
        if (typeof arg === 'function') {
          return (arg as (tx: unknown) => unknown)(prisma);
        }
        return Promise.resolve(arg);
      }),
    };
    // Defaults to the free tier — individual tests opt into Premium via
    // mockResolvedValueOnce(true).
    capabilityService = {
      hasCapabilityForUser: jest.fn().mockResolvedValue(false),
      hasCapabilityForUsers: jest.fn().mockResolvedValue(new Map()),
    };
    notifications = { notify: jest.fn().mockResolvedValue(undefined) };

    const moduleRef = await Test.createTestingModule({
      providers: [
        TrainerGroupsService,
        { provide: PrismaService, useValue: prisma },
        { provide: CapabilityService, useValue: capabilityService },
        { provide: NotificationsService, useValue: notifications },
      ],
    }).compile();

    service = moduleRef.get(TrainerGroupsService);
  });

  describe('createGroup', () => {
    it('rejects creating a second owned group on the free tier', async () => {
      prisma.trainerGroup.count.mockResolvedValue(1);

      await expect(service.createGroup('owner-1', { name: 'Second' })).rejects.toBeInstanceOf(
        ForbiddenException,
      );
      expect(prisma.trainerGroup.create).not.toHaveBeenCalled();
    });

    it('creates the group with the owner auto-added as a member', async () => {
      prisma.trainerGroup.count.mockResolvedValue(0);
      prisma.trainerGroup.create.mockResolvedValue(group());
      prisma.trainerGroup.findUniqueOrThrow.mockResolvedValue({
        ...group(),
        createdAt: new Date(),
        members: [],
      });

      await service.createGroup('owner-1', { name: 'Strong Squad' });

      expect(prisma.trainerGroup.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            ownerId: 'owner-1',
            members: { create: { userId: 'owner-1', role: TrainerGroupMemberRole.OWNER } },
          }),
        }),
      );
    });

    it('allows a Premium owner to own more than the free-tier limit', async () => {
      capabilityService.hasCapabilityForUser.mockResolvedValue(true);
      prisma.trainerGroup.count.mockResolvedValue(1);
      prisma.trainerGroup.create.mockResolvedValue(group());
      prisma.trainerGroup.findUniqueOrThrow.mockResolvedValue({
        ...group(),
        createdAt: new Date(),
        members: [],
      });

      await service.createGroup('owner-1', { name: 'Second' });

      expect(prisma.trainerGroup.create).toHaveBeenCalled();
    });
  });

  describe('listMyGroups', () => {
    it('returns each group correctly serialized, with one batched group fetch and one batched capability lookup regardless of group count', async () => {
      prisma.trainerGroupMember.findMany.mockResolvedValue([
        { groupId: 'group-1' },
        { groupId: 'group-2' },
        { groupId: 'group-3' },
      ]);
      prisma.trainerGroup.findMany.mockResolvedValue([
        {
          ...group({ id: 'group-1', ownerId: 'owner-a', name: 'Group One' }),
          createdAt: new Date('2026-01-01'),
          members: [
            {
              userId: 'member-1',
              role: TrainerGroupMemberRole.OWNER,
              joinedAt: new Date('2026-01-01'),
              user: { communityProfile: { displayName: 'Member One', avatarUrl: null } },
            },
          ],
        },
        {
          ...group({ id: 'group-2', ownerId: 'owner-b', name: 'Group Two' }),
          createdAt: new Date('2026-01-02'),
          members: [],
        },
        {
          ...group({ id: 'group-3', ownerId: 'owner-a', name: 'Group Three' }),
          createdAt: new Date('2026-01-03'),
          members: [],
        },
      ]);
      capabilityService.hasCapabilityForUsers.mockResolvedValue(
        new Map([
          ['owner-a', true],
          ['owner-b', false],
        ]),
      );

      const result = await service.listMyGroups('member-1');

      expect(result.map((g) => g.id)).toEqual(['group-1', 'group-2', 'group-3']);
      expect(result[0]).toMatchObject({ id: 'group-1', ownerId: 'owner-a', isExpanded: true });
      expect(result[0].members).toEqual([
        {
          userId: 'member-1',
          role: TrainerGroupMemberRole.OWNER,
          joinedAt: new Date('2026-01-01'),
          displayName: 'Member One',
          avatarUrl: null,
        },
      ]);
      expect(result[1]).toMatchObject({ id: 'group-2', ownerId: 'owner-b', isExpanded: false });
      expect(result[2]).toMatchObject({ id: 'group-3', ownerId: 'owner-a', isExpanded: true });

      // Query-count regression: exactly one membership lookup, one
      // batched group fetch, and one batched capability lookup — never
      // one findUniqueOrThrow or one capability call per group.
      expect(prisma.trainerGroupMember.findMany).toHaveBeenCalledTimes(1);
      expect(prisma.trainerGroup.findMany).toHaveBeenCalledTimes(1);
      expect(prisma.trainerGroup.findUniqueOrThrow).not.toHaveBeenCalled();
      expect(capabilityService.hasCapabilityForUsers).toHaveBeenCalledTimes(1);
      expect(capabilityService.hasCapabilityForUsers).toHaveBeenCalledWith(
        ['owner-a', 'owner-b', 'owner-a'],
        expect.any(String),
      );
      expect(capabilityService.hasCapabilityForUser).not.toHaveBeenCalled();
    });

    it('returns an empty list without querying groups when the caller has no memberships', async () => {
      prisma.trainerGroupMember.findMany.mockResolvedValue([]);

      const result = await service.listMyGroups('member-1');

      expect(result).toEqual([]);
      expect(prisma.trainerGroup.findMany).not.toHaveBeenCalled();
      expect(capabilityService.hasCapabilityForUsers).not.toHaveBeenCalled();
    });
  });

  describe('invite', () => {
    beforeEach(() => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
    });

    it('rejects a non-owner, non-moderator trying to invite', async () => {
      await expect(
        service.invite('someone-else', 'group-1', { inviteeUserId: 'invitee-1' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.trainerGroupInvitation.upsert).not.toHaveBeenCalled();
    });

    it('allows a moderator to invite', async () => {
      prisma.trainerGroupMember.findUnique
        .mockResolvedValueOnce({ role: TrainerGroupMemberRole.MODERATOR }) // caller role lookup
        .mockResolvedValueOnce(null); // invitee-already-a-member check
      prisma.trainerGroupMember.count.mockResolvedValue(1);
      prisma.trainerGroupInvitation.upsert.mockResolvedValue(invitation());

      await service.invite('moderator-1', 'group-1', { inviteeUserId: 'invitee-1' });

      expect(prisma.trainerGroupInvitation.upsert).toHaveBeenCalled();
    });

    it('rejects inviting yourself', async () => {
      await expect(
        service.invite('owner-1', 'group-1', { inviteeUserId: 'owner-1' }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects inviting someone who is already a member', async () => {
      prisma.trainerGroupMember.findUnique.mockResolvedValue({ id: 'm-1' });

      await expect(
        service.invite('owner-1', 'group-1', { inviteeUserId: 'invitee-1' }),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('404s (not 403s) inviting someone who has blocked the caller', async () => {
      prisma.communityBlock.findUnique.mockResolvedValueOnce({ id: 'block-1' });

      await expect(
        service.invite('owner-1', 'group-1', { inviteeUserId: 'invitee-1' }),
      ).rejects.toBeInstanceOf(NotFoundException);
      expect(prisma.trainerGroupInvitation.upsert).not.toHaveBeenCalled();
    });

    it('404s inviting someone the caller has blocked', async () => {
      prisma.communityBlock.findUnique
        .mockResolvedValueOnce(null) // blocked by invitee
        .mockResolvedValueOnce({ id: 'block-1' }); // blocked by caller

      await expect(
        service.invite('owner-1', 'group-1', { inviteeUserId: 'invitee-1' }),
      ).rejects.toBeInstanceOf(NotFoundException);
      expect(prisma.trainerGroupInvitation.upsert).not.toHaveBeenCalled();
    });

    it('rejects inviting past the free-tier member limit', async () => {
      prisma.trainerGroupMember.findUnique.mockResolvedValue(null);
      prisma.trainerGroupMember.count.mockResolvedValue(5);

      await expect(
        service.invite('owner-1', 'group-1', { inviteeUserId: 'invitee-1' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.trainerGroupInvitation.upsert).not.toHaveBeenCalled();
    });

    it('allows inviting past the free-tier limit once the owner is Premium', async () => {
      capabilityService.hasCapabilityForUser.mockResolvedValue(true);
      prisma.trainerGroupMember.findUnique.mockResolvedValue(null);
      prisma.trainerGroupMember.count.mockResolvedValue(5);
      prisma.trainerGroupInvitation.upsert.mockResolvedValue(invitation());

      await service.invite('owner-1', 'group-1', { inviteeUserId: 'invitee-1' });

      expect(prisma.trainerGroupInvitation.upsert).toHaveBeenCalled();
    });

    it('upserts a PENDING invitation when everything checks out', async () => {
      prisma.trainerGroupMember.findUnique.mockResolvedValue(null);
      prisma.trainerGroupMember.count.mockResolvedValue(1);
      prisma.trainerGroupInvitation.upsert.mockResolvedValue(invitation());

      await service.invite('owner-1', 'group-1', { inviteeUserId: 'invitee-1' });

      expect(prisma.trainerGroupInvitation.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { groupId_inviteeId: { groupId: 'group-1', inviteeId: 'invitee-1' } },
        }),
      );
    });
  });

  describe('respondToInvitation', () => {
    it('rejects when the caller is not the invitee', async () => {
      prisma.trainerGroupInvitation.findUnique.mockResolvedValue(
        invitation({ inviteeId: 'someone-else' }),
      );

      await expect(
        service.respondToInvitation('invitee-1', 'invite-1', true),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('rejects responding to an already-resolved invitation', async () => {
      prisma.trainerGroupInvitation.findUnique.mockResolvedValue(
        invitation({ status: TrainerGroupInvitationStatus.ACCEPTED }),
      );

      await expect(
        service.respondToInvitation('invitee-1', 'invite-1', true),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('declining only updates the invitation status, no membership created', async () => {
      prisma.trainerGroupInvitation.findUnique.mockResolvedValue(invitation());

      const result = await service.respondToInvitation('invitee-1', 'invite-1', false);

      expect(result.status).toBe(TrainerGroupInvitationStatus.DECLINED);
      expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    it('rejects accepting once the group is at its member limit', async () => {
      prisma.trainerGroupInvitation.findUnique.mockResolvedValue(invitation());
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupMember.count.mockResolvedValue(5);

      await expect(
        service.respondToInvitation('invitee-1', 'invite-1', true),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    it('accepting creates the membership and marks the invitation ACCEPTED in one transaction', async () => {
      prisma.trainerGroupInvitation.findUnique.mockResolvedValue(invitation());
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupMember.count.mockResolvedValue(1);

      const result = await service.respondToInvitation('invitee-1', 'invite-1', true);

      expect(result.status).toBe(TrainerGroupInvitationStatus.ACCEPTED);
      expect(prisma.$transaction).toHaveBeenCalledTimes(1);
      expect(prisma.trainerGroupMember.create).toHaveBeenCalledWith({
        data: { groupId: 'group-1', userId: 'invitee-1', role: TrainerGroupMemberRole.MEMBER },
      });
    });
  });

  describe('cancelInvitation', () => {
    it('rejects a bystander who is neither the inviter nor the group owner', async () => {
      prisma.trainerGroupInvitation.findUnique.mockResolvedValue(invitation());
      prisma.trainerGroup.findUnique.mockResolvedValue(group());

      await expect(service.cancelInvitation('bystander', 'invite-1')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });
  });

  describe('removeMember', () => {
    it('rejects removing the group owner', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());

      await expect(service.removeMember('owner-1', 'group-1', 'owner-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('rejects one member removing a different member', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());

      await expect(service.removeMember('member-a', 'group-1', 'member-b')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });

    it('allows a member to remove themselves (leave)', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupMember.findUnique.mockResolvedValue({ id: 'membership-1' });

      await service.removeMember('member-a', 'group-1', 'member-a');

      expect(prisma.trainerGroupMember.delete).toHaveBeenCalledWith({
        where: { id: 'membership-1' },
      });
    });

    it('allows a moderator to remove a regular member', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupMember.findUnique
        .mockResolvedValueOnce({ role: TrainerGroupMemberRole.MODERATOR }) // caller role
        .mockResolvedValueOnce({ role: TrainerGroupMemberRole.MEMBER }) // target role
        .mockResolvedValueOnce({ id: 'membership-1' }); // target membership row to delete

      await service.removeMember('moderator-1', 'group-1', 'member-b');

      expect(prisma.trainerGroupMember.delete).toHaveBeenCalledWith({
        where: { id: 'membership-1' },
      });
    });

    it('rejects a moderator trying to remove another moderator', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupMember.findUnique
        .mockResolvedValueOnce({ role: TrainerGroupMemberRole.MODERATOR }) // caller role
        .mockResolvedValueOnce({ role: TrainerGroupMemberRole.MODERATOR }); // target role

      await expect(
        service.removeMember('moderator-1', 'group-1', 'moderator-2'),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.trainerGroupMember.delete).not.toHaveBeenCalled();
    });
  });

  describe('setMemberRole', () => {
    it('rejects a non-owner', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());

      await expect(
        service.setMemberRole('someone-else', 'group-1', 'member-a', { role: 'MODERATOR' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('rejects changing the owner’s own role', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());

      await expect(
        service.setMemberRole('owner-1', 'group-1', 'owner-1', { role: 'MEMBER' }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects on the free tier', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());

      await expect(
        service.setMemberRole('owner-1', 'group-1', 'member-a', { role: 'MODERATOR' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.trainerGroupMember.update).not.toHaveBeenCalled();
    });

    it('promotes a member to MODERATOR once the owner is Premium', async () => {
      capabilityService.hasCapabilityForUser.mockResolvedValue(true);
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupMember.findUnique.mockResolvedValue({
        id: 'membership-1',
        role: TrainerGroupMemberRole.MEMBER,
      });
      prisma.trainerGroupMember.update.mockResolvedValue({
        userId: 'member-a',
        role: TrainerGroupMemberRole.MODERATOR,
      });

      const result = await service.setMemberRole('owner-1', 'group-1', 'member-a', {
        role: 'MODERATOR',
      });

      expect(result).toEqual({ userId: 'member-a', role: TrainerGroupMemberRole.MODERATOR });
      expect(prisma.trainerGroupMember.update).toHaveBeenCalledWith({
        where: { id: 'membership-1' },
        data: { role: TrainerGroupMemberRole.MODERATOR },
      });
    });
  });

  describe('postAnnouncement', () => {
    it('rejects a regular member', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupMember.findUnique.mockResolvedValue({
        role: TrainerGroupMemberRole.MEMBER,
      });

      await expect(
        service.postAnnouncement('member-a', 'group-1', { body: 'Leg day tomorrow!' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('rejects on the free tier even for the owner', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupMember.findUnique.mockResolvedValue({
        role: TrainerGroupMemberRole.OWNER,
      });

      await expect(
        service.postAnnouncement('owner-1', 'group-1', { body: 'Leg day tomorrow!' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.trainerGroupAnnouncement.create).not.toHaveBeenCalled();
    });

    it('lets the owner post once Premium', async () => {
      capabilityService.hasCapabilityForUser.mockResolvedValue(true);
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupMember.findUnique.mockResolvedValue({
        role: TrainerGroupMemberRole.OWNER,
      });
      prisma.trainerGroupAnnouncement.create.mockResolvedValue({
        id: 'ann-1',
        groupId: 'group-1',
        authorId: 'owner-1',
        body: 'Leg day tomorrow!',
        createdAt: new Date(),
      });

      const result = await service.postAnnouncement('owner-1', 'group-1', {
        body: 'Leg day tomorrow!',
      });

      expect(result.id).toBe('ann-1');
    });
  });

  describe('resolveGroupSessionInvitees', () => {
    it('rejects a regular member', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupMember.findUnique.mockResolvedValue({
        role: TrainerGroupMemberRole.MEMBER,
      });

      await expect(
        service.resolveGroupSessionInvitees('member-a', 'group-1'),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.trainerGroupMember.findMany).not.toHaveBeenCalled();
    });

    it('rejects on the free tier even for the owner', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupMember.findUnique.mockResolvedValue({
        role: TrainerGroupMemberRole.OWNER,
      });

      await expect(
        service.resolveGroupSessionInvitees('owner-1', 'group-1'),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.trainerGroupMember.findMany).not.toHaveBeenCalled();
    });

    it(
      'returns every other member for the owner once Premium, excluding the ' + 'caller themselves',
      async () => {
        capabilityService.hasCapabilityForUser.mockResolvedValue(true);
        prisma.trainerGroup.findUnique.mockResolvedValue(group());
        prisma.trainerGroupMember.findUnique.mockResolvedValue({
          role: TrainerGroupMemberRole.OWNER,
        });
        prisma.trainerGroupMember.findMany.mockResolvedValue([
          { userId: 'owner-1' },
          { userId: 'member-a' },
          { userId: 'member-b' },
        ]);

        const result = await service.resolveGroupSessionInvitees('owner-1', 'group-1');

        expect(result).toEqual(['member-a', 'member-b']);
      },
    );

    it('lets a moderator on a Premium owner’s group schedule too', async () => {
      capabilityService.hasCapabilityForUser.mockResolvedValue(true);
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupMember.findUnique.mockResolvedValue({
        role: TrainerGroupMemberRole.MODERATOR,
      });
      prisma.trainerGroupMember.findMany.mockResolvedValue([
        { userId: 'owner-1' },
        { userId: 'mod-1' },
        { userId: 'member-a' },
      ]);

      const result = await service.resolveGroupSessionInvitees('mod-1', 'group-1');

      expect(result).toEqual(['owner-1', 'member-a']);
    });
  });

  describe('sendMessage', () => {
    it('rejects a message with neither text nor an image', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupMember.findUnique.mockResolvedValue({ id: 'membership-1' });

      await expect(service.sendMessage('owner-1', 'group-1', {})).rejects.toBeInstanceOf(
        BadRequestException,
      );
      expect(prisma.trainerGroupMessage.create).not.toHaveBeenCalled();
    });
  });

  describe('sharePlan', () => {
    it('rejects sharing a plan you do not own', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupMember.findUnique.mockResolvedValue({ id: 'membership-1' });
      prisma.workoutPlan.findUnique.mockResolvedValue({ id: 'plan-1', userId: 'someone-else' });

      await expect(
        service.sharePlan('owner-1', 'group-1', { workoutPlanId: 'plan-1' }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  describe('unsharePlan', () => {
    it('rejects a bystander who neither shared the plan nor owns the group', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupSharedPlan.findUnique.mockResolvedValue({
        id: 'shared-1',
        groupId: 'group-1',
        sharedById: 'someone-else',
      });

      await expect(service.unsharePlan('bystander', 'group-1', 'shared-1')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });
  });

  describe('createAssignments (Build Session 12 Part 9)', () => {
    it('rejects assigning a plan the caller does not own', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.workoutPlan.findUnique.mockResolvedValue({ id: 'plan-1', userId: 'someone-else' });

      await expect(
        service.createAssignments('owner-1', 'group-1', {
          workoutPlanId: 'plan-1',
          assigneeUserIds: ['member-a'],
        }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('rejects an assignee who is not a member of the group', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.workoutPlan.findUnique.mockResolvedValue({ id: 'plan-1', userId: 'owner-1' });
      prisma.trainerGroupMember.findMany.mockResolvedValue([]);

      await expect(
        service.createAssignments('owner-1', 'group-1', {
          workoutPlanId: 'plan-1',
          assigneeUserIds: ['not-a-member'],
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects a plain member (neither owner nor moderator) assigning a workout', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupMember.findUnique.mockResolvedValue({
        role: TrainerGroupMemberRole.MEMBER,
      });

      await expect(
        service.createAssignments('member-a', 'group-1', {
          workoutPlanId: 'plan-1',
          assigneeUserIds: ['member-b'],
        }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('creates one assignment per assignee and notifies each of them', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.workoutPlan.findUnique.mockResolvedValue({
        id: 'plan-1',
        userId: 'owner-1',
        name: 'Push Day',
      });
      prisma.trainerGroupMember.findMany.mockResolvedValue([
        { userId: 'member-a' },
        { userId: 'member-b' },
      ]);
      prisma.workoutAssignment.create.mockImplementation(
        (args: { data: Record<string, unknown> }) =>
          Promise.resolve({
            id: `assignment-${args.data.assigneeId as string}`,
            status: WorkoutAssignmentStatus.PENDING,
            assignedPlanId: null,
            note: null,
            dueAt: null,
            createdAt: new Date(),
            completedAt: null,
            ...args.data,
          }),
      );

      const result = await service.createAssignments('owner-1', 'group-1', {
        workoutPlanId: 'plan-1',
        assigneeUserIds: ['member-a', 'member-b'],
      });

      expect(result).toHaveLength(2);
      expect(notifications.notify).toHaveBeenCalledTimes(2);
      expect(notifications.notify).toHaveBeenCalledWith(
        'member-a',
        'WORKOUT_ASSIGNED',
        expect.any(String),
        expect.stringContaining('Push Day'),
        'assignment-member-a',
      );
    });
  });

  describe('acceptAssignment', () => {
    it('rejects an assignment that does not belong to the caller', async () => {
      prisma.workoutAssignment.findUnique.mockResolvedValue({
        id: 'assignment-1',
        assigneeId: 'someone-else',
        status: WorkoutAssignmentStatus.PENDING,
      });

      await expect(service.acceptAssignment('member-a', 'assignment-1')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('rejects re-accepting an assignment that already has a response', async () => {
      prisma.workoutAssignment.findUnique.mockResolvedValue({
        id: 'assignment-1',
        assigneeId: 'member-a',
        status: WorkoutAssignmentStatus.ACCEPTED,
      });

      await expect(service.acceptAssignment('member-a', 'assignment-1')).rejects.toBeInstanceOf(
        ConflictException,
      );
    });

    it('clones the source plan’s exercises into a new plan owned by the assignee', async () => {
      prisma.workoutAssignment.findUnique.mockResolvedValue({
        id: 'assignment-1',
        assigneeId: 'member-a',
        status: WorkoutAssignmentStatus.PENDING,
        sourcePlan: {
          name: 'Push Day',
          description: 'Chest, shoulders, triceps',
          exercises: [
            {
              exerciseId: 'exercise-1',
              order: 1,
              targetSets: 3,
              targetReps: 10,
              targetDurationSeconds: null,
              targetWeightKg: null,
              targetDistanceMeters: null,
              restSeconds: 60,
              notes: null,
            },
          ],
        },
      });
      prisma.workoutPlan.create.mockResolvedValue({ id: 'cloned-plan-1' });
      prisma.workoutAssignment.update.mockResolvedValue({});

      const result = await service.acceptAssignment('member-a', 'assignment-1');

      expect(prisma.workoutPlan.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ userId: 'member-a', name: 'Push Day' }),
        }),
      );
      expect(prisma.workoutAssignment.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            status: WorkoutAssignmentStatus.ACCEPTED,
            assignedPlanId: 'cloned-plan-1',
          }),
        }),
      );
      expect(result).toEqual({ assignmentId: 'assignment-1', workoutPlanId: 'cloned-plan-1' });
    });
  });

  describe('cancelAssignment', () => {
    it('rejects a bystander who is neither the assigner nor the assignee', async () => {
      prisma.workoutAssignment.findUnique.mockResolvedValue({
        id: 'assignment-1',
        assignedById: 'owner-1',
        assigneeId: 'member-a',
        status: WorkoutAssignmentStatus.PENDING,
      });

      await expect(service.cancelAssignment('bystander', 'assignment-1')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });

    it('rejects removing a completed assignment', async () => {
      prisma.workoutAssignment.findUnique.mockResolvedValue({
        id: 'assignment-1',
        assignedById: 'owner-1',
        assigneeId: 'member-a',
        status: WorkoutAssignmentStatus.COMPLETED,
      });

      await expect(service.cancelAssignment('member-a', 'assignment-1')).rejects.toBeInstanceOf(
        ConflictException,
      );
    });

    it('lets the assignee remove their own pending assignment', async () => {
      prisma.workoutAssignment.findUnique.mockResolvedValue({
        id: 'assignment-1',
        assignedById: 'owner-1',
        assigneeId: 'member-a',
        status: WorkoutAssignmentStatus.PENDING,
      });

      await service.cancelAssignment('member-a', 'assignment-1');

      expect(prisma.workoutAssignment.delete).toHaveBeenCalledWith({
        where: { id: 'assignment-1' },
      });
    });
  });

  describe('completeAssignmentsForSession', () => {
    it('is a no-op when the session has no workout plan', async () => {
      await service.completeAssignmentsForSession('member-a', null);

      expect(prisma.workoutAssignment.updateMany).not.toHaveBeenCalled();
    });

    it('marks only the matching accepted assignment as completed', async () => {
      await service.completeAssignmentsForSession('member-a', 'cloned-plan-1');

      expect(prisma.workoutAssignment.updateMany).toHaveBeenCalledWith({
        where: {
          assigneeId: 'member-a',
          assignedPlanId: 'cloned-plan-1',
          status: WorkoutAssignmentStatus.ACCEPTED,
        },
        data: { status: WorkoutAssignmentStatus.COMPLETED, completedAt: expect.any(Date) },
      });
    });
  });

  describe('createScheduledSession (Build Session 12 Part 10)', () => {
    it('rejects a non-expanded (free-tier) owner scheduling a session', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      capabilityService.hasCapabilityForUser.mockResolvedValue(false);

      await expect(
        service.createScheduledSession('owner-1', 'group-1', {
          scheduledAt: new Date(Date.now() + 86_400_000).toISOString(),
        }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('rejects a scheduledAt that is not in the future', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      capabilityService.hasCapabilityForUser.mockResolvedValue(true);

      await expect(
        service.createScheduledSession('owner-1', 'group-1', {
          scheduledAt: new Date(Date.now() - 86_400_000).toISOString(),
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('creates the session and notifies every other member', async () => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      capabilityService.hasCapabilityForUser.mockResolvedValue(true);
      const scheduledAt = new Date(Date.now() + 86_400_000);
      prisma.trainerGroupScheduledSession.create.mockResolvedValue({
        id: 'session-1',
        groupId: 'group-1',
        createdById: 'owner-1',
        title: null,
        scheduledAt,
        durationMinutes: null,
        location: null,
        videoLink: null,
        description: null,
        canceledAt: null,
        createdAt: new Date(),
      });
      prisma.trainerGroupMember.findMany.mockResolvedValue([
        { userId: 'member-a' },
        { userId: 'member-b' },
      ]);

      const result = await service.createScheduledSession('owner-1', 'group-1', {
        scheduledAt: scheduledAt.toISOString(),
      });

      expect(result.id).toBe('session-1');
      expect(notifications.notify).toHaveBeenCalledTimes(2);
      expect(notifications.notify).toHaveBeenCalledWith(
        'member-a',
        'GROUP_SESSION_SCHEDULED',
        expect.any(String),
        expect.any(String),
        'session-1',
      );
    });
  });

  describe('cancelScheduledSession', () => {
    it('rejects a bystander who neither created it nor owns the group', async () => {
      prisma.trainerGroupScheduledSession.findUnique.mockResolvedValue({
        id: 'session-1',
        groupId: 'group-1',
        createdById: 'owner-1',
        canceledAt: null,
      });
      prisma.trainerGroup.findUnique.mockResolvedValue(group());

      await expect(service.cancelScheduledSession('bystander', 'session-1')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });

    it('rejects canceling an already-canceled session', async () => {
      prisma.trainerGroupScheduledSession.findUnique.mockResolvedValue({
        id: 'session-1',
        groupId: 'group-1',
        createdById: 'owner-1',
        canceledAt: new Date(),
      });
      prisma.trainerGroup.findUnique.mockResolvedValue(group());

      await expect(service.cancelScheduledSession('owner-1', 'session-1')).rejects.toBeInstanceOf(
        ConflictException,
      );
    });

    it('notifies every other member that the session was canceled', async () => {
      prisma.trainerGroupScheduledSession.findUnique.mockResolvedValue({
        id: 'session-1',
        groupId: 'group-1',
        createdById: 'owner-1',
        canceledAt: null,
      });
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupMember.findMany.mockResolvedValue([
        { userId: 'member-a' },
        { userId: 'member-b' },
      ]);

      await service.cancelScheduledSession('owner-1', 'session-1');

      expect(prisma.trainerGroupScheduledSession.update).toHaveBeenCalledWith({
        where: { id: 'session-1' },
        data: { canceledAt: expect.any(Date) },
      });
      expect(notifications.notify).toHaveBeenCalledTimes(2);
      expect(notifications.notify).toHaveBeenCalledWith(
        'member-a',
        'GROUP_SESSION_CANCELED',
        expect.any(String),
        expect.any(String),
        'session-1',
      );
    });
  });

  function scheduledSession(overrides: Partial<Record<string, unknown>> = {}) {
    return {
      id: 'session-1',
      groupId: 'group-1',
      createdById: 'owner-1',
      title: 'Squad session',
      scheduledAt: new Date(Date.now() + 86_400_000),
      durationMinutes: 45,
      location: null,
      videoLink: null,
      description: null,
      workoutPlanId: null,
      canceledAt: null,
      createdAt: new Date(),
      workoutPlan: null,
      ...overrides,
    };
  }

  describe('rsvpToScheduledSession (Build Session 13 Part 3)', () => {
    it('404s a session that does not exist', async () => {
      prisma.trainerGroupScheduledSession.findUnique.mockResolvedValue(null);

      await expect(
        service.rsvpToScheduledSession(
          'member-a',
          'missing',
          TrainerGroupScheduledSessionRsvpStatus.GOING,
        ),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('rejects RSVPing to a canceled session', async () => {
      prisma.trainerGroupScheduledSession.findUnique.mockResolvedValue(
        scheduledSession({ canceledAt: new Date() }),
      );

      await expect(
        service.rsvpToScheduledSession(
          'member-a',
          'session-1',
          TrainerGroupScheduledSessionRsvpStatus.GOING,
        ),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('rejects a non-member', async () => {
      prisma.trainerGroupScheduledSession.findUnique.mockResolvedValue(scheduledSession());
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupMember.findUnique.mockResolvedValue(null);

      await expect(
        service.rsvpToScheduledSession(
          'stranger',
          'session-1',
          TrainerGroupScheduledSessionRsvpStatus.MAYBE,
        ),
      ).rejects.toBeInstanceOf(NotFoundException);
      expect(prisma.trainerGroupScheduledSessionParticipant.upsert).not.toHaveBeenCalled();
    });

    it('upserts the RSVP and returns updated counts', async () => {
      prisma.trainerGroupScheduledSession.findUnique.mockResolvedValue(scheduledSession());
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupMember.findUnique.mockResolvedValue({
        role: TrainerGroupMemberRole.MEMBER,
      });
      prisma.trainerGroupScheduledSessionParticipant.groupBy.mockResolvedValue([
        { sessionId: 'session-1', status: 'GOING', _count: { _all: 1 } },
      ]);
      prisma.trainerGroupScheduledSessionParticipant.findMany.mockResolvedValue([
        { sessionId: 'session-1', status: 'GOING' },
      ]);

      const result = await service.rsvpToScheduledSession(
        'member-a',
        'session-1',
        TrainerGroupScheduledSessionRsvpStatus.GOING,
      );

      expect(prisma.trainerGroupScheduledSessionParticipant.upsert).toHaveBeenCalledWith({
        where: { sessionId_userId: { sessionId: 'session-1', userId: 'member-a' } },
        create: { sessionId: 'session-1', userId: 'member-a', status: 'GOING' },
        update: { status: 'GOING', respondedAt: expect.any(Date) },
      });
      expect(result.goingCount).toBe(1);
      expect(result.viewerRsvpStatus).toBe('GOING');
    });

    it('rejects a new GOING RSVP once the session is at its participant limit', async () => {
      prisma.trainerGroupScheduledSession.findUnique.mockResolvedValue(scheduledSession());
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupMember.findUnique.mockResolvedValue({
        role: TrainerGroupMemberRole.MEMBER,
      });
      prisma.trainerGroupScheduledSessionParticipant.findUnique.mockResolvedValue(null);
      capabilityService.hasCapabilityForUser.mockResolvedValue(false);
      prisma.trainerGroupScheduledSessionParticipant.count.mockResolvedValue(5); // TRAINER_GROUP_SESSION_GOING_LIMIT_FREE

      await expect(
        service.rsvpToScheduledSession(
          'member-f',
          'session-1',
          TrainerGroupScheduledSessionRsvpStatus.GOING,
        ),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.trainerGroupScheduledSessionParticipant.upsert).not.toHaveBeenCalled();
    });

    it('allows re-confirming an existing GOING RSVP even at the limit', async () => {
      prisma.trainerGroupScheduledSession.findUnique.mockResolvedValue(scheduledSession());
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupMember.findUnique.mockResolvedValue({
        role: TrainerGroupMemberRole.MEMBER,
      });
      prisma.trainerGroupScheduledSessionParticipant.findUnique.mockResolvedValue({
        status: 'GOING',
      });
      capabilityService.hasCapabilityForUser.mockResolvedValue(false);
      prisma.trainerGroupScheduledSessionParticipant.count.mockResolvedValue(5);

      await service.rsvpToScheduledSession(
        'member-a',
        'session-1',
        TrainerGroupScheduledSessionRsvpStatus.GOING,
      );

      expect(prisma.trainerGroupScheduledSessionParticipant.upsert).toHaveBeenCalled();
    });
  });

  describe('cancelMyRsvp', () => {
    it('404s a session that does not exist', async () => {
      prisma.trainerGroupScheduledSession.findUnique.mockResolvedValue(null);

      await expect(service.cancelMyRsvp('member-a', 'missing')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('deletes the RSVP row and is idempotent when none exists', async () => {
      prisma.trainerGroupScheduledSession.findUnique.mockResolvedValue(scheduledSession());
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
      prisma.trainerGroupMember.findUnique.mockResolvedValue({
        role: TrainerGroupMemberRole.MEMBER,
      });

      const result = await service.cancelMyRsvp('member-a', 'session-1');

      expect(prisma.trainerGroupScheduledSessionParticipant.deleteMany).toHaveBeenCalledWith({
        where: { sessionId: 'session-1', userId: 'member-a' },
      });
      expect(result.viewerRsvpStatus).toBeNull();
    });
  });

  describe('getTrainerDashboard', () => {
    it('returns an empty dashboard for a caller who owns/moderates no groups', async () => {
      prisma.trainerGroupMember.findMany.mockResolvedValue([]);

      const result = await service.getTrainerDashboard('nobody');

      expect(result).toEqual({ groups: [], upcomingSessions: [], recentAssignments: [] });
    });

    it('aggregates member counts and pending assignments per owned group', async () => {
      prisma.trainerGroupMember.findMany.mockResolvedValue([{ groupId: 'group-1' }]);
      prisma.trainerGroup.findMany.mockResolvedValue([
        { id: 'group-1', name: 'Strong Squad', _count: { members: 3 } },
      ]);
      prisma.trainerGroupScheduledSession.findMany.mockResolvedValue([]);
      prisma.workoutAssignment.findMany.mockResolvedValue([]);
      prisma.workoutAssignment.groupBy.mockResolvedValue([
        { groupId: 'group-1', _count: { _all: 2 } },
      ]);

      const result = await service.getTrainerDashboard('owner-1');

      expect(result.groups).toEqual([
        { id: 'group-1', name: 'Strong Squad', memberCount: 3, pendingAssignmentCount: 2 },
      ]);
    });
  });
});
