import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { TrainerGroupInvitationStatus, TrainerGroupMemberRole } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
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
  let prisma: {
    trainerGroup: {
      count: jest.Mock;
      create: jest.Mock;
      findUnique: jest.Mock;
      findUniqueOrThrow: jest.Mock;
      delete: jest.Mock;
    };
    trainerGroupMember: {
      count: jest.Mock;
      findUnique: jest.Mock;
      create: jest.Mock;
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
    workoutPlan: { findUnique: jest.Mock };
    $transaction: jest.Mock;
  };

  beforeEach(async () => {
    prisma = {
      trainerGroup: {
        count: jest.fn(),
        create: jest.fn(),
        findUnique: jest.fn(),
        findUniqueOrThrow: jest.fn(),
        delete: jest.fn(),
      },
      trainerGroupMember: {
        count: jest.fn(),
        findUnique: jest.fn(),
        create: jest.fn(),
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
      workoutPlan: { findUnique: jest.fn() },
      $transaction: jest.fn((ops: unknown[]) => Promise.resolve(ops)),
    };

    const moduleRef = await Test.createTestingModule({
      providers: [TrainerGroupsService, { provide: PrismaService, useValue: prisma }],
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
  });

  describe('invite', () => {
    beforeEach(() => {
      prisma.trainerGroup.findUnique.mockResolvedValue(group());
    });

    it('rejects a non-owner trying to invite', async () => {
      await expect(
        service.invite('someone-else', 'group-1', { inviteeUserId: 'invitee-1' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.trainerGroupInvitation.upsert).not.toHaveBeenCalled();
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

    it('rejects inviting past the free-tier member limit', async () => {
      prisma.trainerGroupMember.findUnique.mockResolvedValue(null);
      prisma.trainerGroupMember.count.mockResolvedValue(5);

      await expect(
        service.invite('owner-1', 'group-1', { inviteeUserId: 'invitee-1' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.trainerGroupInvitation.upsert).not.toHaveBeenCalled();
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
      prisma.trainerGroupMember.count.mockResolvedValue(5);

      await expect(
        service.respondToInvitation('invitee-1', 'invite-1', true),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    it('accepting creates the membership and marks the invitation ACCEPTED in one transaction', async () => {
      prisma.trainerGroupInvitation.findUnique.mockResolvedValue(invitation());
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
});
