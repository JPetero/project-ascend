import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { TrainerGroupInvitationStatus, TrainerGroupMemberRole } from '@prisma/client';
import {
  TRAINER_GROUP_MEMBER_LIMIT_FREE,
  TRAINER_GROUP_OWNED_LIMIT_FREE,
} from '../../common/policy/trainer-group-policy';
import {
  PaginationQueryDto,
  paginationArgs,
  paginationMeta,
} from '../../common/pagination/pagination-query.dto';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateTrainerGroupDto } from './dto/create-trainer-group.dto';
import { InviteTrainerGroupMemberDto } from './dto/invite-trainer-group-member.dto';
import { SendTrainerGroupMessageDto } from './dto/send-trainer-group-message.dto';
import { ShareTrainerGroupPlanDto } from './dto/share-trainer-group-plan.dto';

/**
 * Trainer groups (free tier) — one owned group per user, a small
 * centrally-configured member limit, text/image chat, shared workout
 * plans, and invitations. See schema.prisma's Trainer group comment and
 * packages/docs/product/user-scenario-bible.md Scenario 24. Premium
 * roles/scale (Scenario 24's Premium-future list) are not implemented.
 */
@Injectable()
export class TrainerGroupsService {
  constructor(private readonly prisma: PrismaService) {}

  // --- Groups -----------------------------------------------------------

  async createGroup(userId: string, dto: CreateTrainerGroupDto) {
    const ownedCount = await this.prisma.trainerGroup.count({ where: { ownerId: userId } });
    if (ownedCount >= TRAINER_GROUP_OWNED_LIMIT_FREE) {
      throw new ForbiddenException(
        `You can own at most ${TRAINER_GROUP_OWNED_LIMIT_FREE} group on the free tier.`,
      );
    }

    const group = await this.prisma.trainerGroup.create({
      data: {
        ownerId: userId,
        name: dto.name,
        description: dto.description,
        members: { create: { userId, role: TrainerGroupMemberRole.OWNER } },
      },
    });
    return this.serializeGroup(group.id, userId);
  }

  async listMyGroups(userId: string) {
    const memberships = await this.prisma.trainerGroupMember.findMany({
      where: { userId },
      select: { groupId: true },
    });
    return Promise.all(memberships.map((m) => this.serializeGroup(m.groupId, userId)));
  }

  async getGroup(userId: string, groupId: string) {
    await this.assertMember(userId, groupId);
    return this.serializeGroup(groupId, userId);
  }

  async deleteGroup(userId: string, groupId: string): Promise<void> {
    const group = await this.findGroup(groupId);
    if (group.ownerId !== userId) {
      throw new ForbiddenException('Only the group owner can delete this group.');
    }
    await this.prisma.trainerGroup.delete({ where: { id: groupId } });
  }

  // --- Membership and invitations ----------------------------------------

  async invite(userId: string, groupId: string, dto: InviteTrainerGroupMemberDto) {
    const group = await this.findGroup(groupId);
    if (group.ownerId !== userId) {
      throw new ForbiddenException('Only the group owner can invite members.');
    }
    if (dto.inviteeUserId === userId) {
      throw new BadRequestException('You cannot invite yourself.');
    }
    const alreadyMember = await this.prisma.trainerGroupMember.findUnique({
      where: { groupId_userId: { groupId, userId: dto.inviteeUserId } },
    });
    if (alreadyMember) {
      throw new ConflictException('This person is already a member of the group.');
    }
    const memberCount = await this.prisma.trainerGroupMember.count({ where: { groupId } });
    if (memberCount >= TRAINER_GROUP_MEMBER_LIMIT_FREE) {
      throw new ForbiddenException(
        `This group is at its ${TRAINER_GROUP_MEMBER_LIMIT_FREE}-member free-tier limit.`,
      );
    }

    const invitation = await this.prisma.trainerGroupInvitation.upsert({
      where: { groupId_inviteeId: { groupId, inviteeId: dto.inviteeUserId } },
      update: { status: TrainerGroupInvitationStatus.PENDING, inviterId: userId },
      create: {
        groupId,
        inviterId: userId,
        inviteeId: dto.inviteeUserId,
        status: TrainerGroupInvitationStatus.PENDING,
      },
    });
    return this.serializeInvitation(invitation);
  }

  async listMyInvitations(userId: string) {
    const invitations = await this.prisma.trainerGroupInvitation.findMany({
      where: { inviteeId: userId, status: TrainerGroupInvitationStatus.PENDING },
      orderBy: { createdAt: 'desc' },
    });
    return invitations.map((i) => this.serializeInvitation(i));
  }

  async respondToInvitation(userId: string, invitationId: string, accept: boolean) {
    const invitation = await this.prisma.trainerGroupInvitation.findUnique({
      where: { id: invitationId },
    });
    if (!invitation || invitation.inviteeId !== userId) {
      throw new NotFoundException('Invitation not found.');
    }
    if (invitation.status !== TrainerGroupInvitationStatus.PENDING) {
      throw new ConflictException('This invitation has already been responded to.');
    }

    if (!accept) {
      await this.prisma.trainerGroupInvitation.update({
        where: { id: invitationId },
        data: { status: TrainerGroupInvitationStatus.DECLINED },
      });
      return { status: TrainerGroupInvitationStatus.DECLINED };
    }

    const memberCount = await this.prisma.trainerGroupMember.count({
      where: { groupId: invitation.groupId },
    });
    if (memberCount >= TRAINER_GROUP_MEMBER_LIMIT_FREE) {
      throw new ForbiddenException(
        `This group is now at its ${TRAINER_GROUP_MEMBER_LIMIT_FREE}-member free-tier limit.`,
      );
    }

    await this.prisma.$transaction([
      this.prisma.trainerGroupMember.create({
        data: { groupId: invitation.groupId, userId, role: TrainerGroupMemberRole.MEMBER },
      }),
      this.prisma.trainerGroupInvitation.update({
        where: { id: invitationId },
        data: { status: TrainerGroupInvitationStatus.ACCEPTED },
      }),
    ]);
    return { status: TrainerGroupInvitationStatus.ACCEPTED };
  }

  async cancelInvitation(userId: string, invitationId: string): Promise<void> {
    const invitation = await this.prisma.trainerGroupInvitation.findUnique({
      where: { id: invitationId },
    });
    if (!invitation) throw new NotFoundException('Invitation not found.');
    const group = await this.findGroup(invitation.groupId);
    const canCancel = invitation.inviterId === userId || group.ownerId === userId;
    if (!canCancel) {
      throw new ForbiddenException(
        'Only the inviter or the group owner can cancel this invitation.',
      );
    }
    if (invitation.status !== TrainerGroupInvitationStatus.PENDING) {
      throw new ConflictException('This invitation is no longer pending.');
    }
    await this.prisma.trainerGroupInvitation.update({
      where: { id: invitationId },
      data: { status: TrainerGroupInvitationStatus.CANCELED },
    });
  }

  async removeMember(userId: string, groupId: string, targetUserId: string): Promise<void> {
    const group = await this.findGroup(groupId);
    const isSelf = userId === targetUserId;
    if (targetUserId === group.ownerId) {
      throw new BadRequestException(
        'The group owner cannot be removed — delete the group instead.',
      );
    }
    if (!isSelf && group.ownerId !== userId) {
      throw new ForbiddenException('Only the group owner can remove another member.');
    }
    const membership = await this.prisma.trainerGroupMember.findUnique({
      where: { groupId_userId: { groupId, userId: targetUserId } },
    });
    if (!membership) throw new NotFoundException('This person is not a member of the group.');
    await this.prisma.trainerGroupMember.delete({ where: { id: membership.id } });
  }

  // --- Messages ---------------------------------------------------------

  async sendMessage(userId: string, groupId: string, dto: SendTrainerGroupMessageDto) {
    await this.assertMember(userId, groupId);
    if (!dto.body && !dto.imageUrl) {
      throw new BadRequestException('A message needs text, an image, or both.');
    }
    const message = await this.prisma.trainerGroupMessage.create({
      data: { groupId, authorId: userId, body: dto.body, imageUrl: dto.imageUrl },
    });
    return {
      id: message.id,
      groupId: message.groupId,
      authorId: message.authorId,
      body: message.body,
      imageUrl: message.imageUrl,
      createdAt: message.createdAt,
    };
  }

  async listMessages(userId: string, groupId: string, query: PaginationQueryDto) {
    await this.assertMember(userId, groupId);
    const where = { groupId };
    const [messages, total] = await Promise.all([
      this.prisma.trainerGroupMessage.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        ...paginationArgs(query),
      }),
      this.prisma.trainerGroupMessage.count({ where }),
    ]);
    return {
      data: messages.map((m) => ({
        id: m.id,
        groupId: m.groupId,
        authorId: m.authorId,
        body: m.body,
        imageUrl: m.imageUrl,
        createdAt: m.createdAt,
      })),
      meta: paginationMeta(query, total),
    };
  }

  // --- Shared plans -----------------------------------------------------

  async sharePlan(userId: string, groupId: string, dto: ShareTrainerGroupPlanDto) {
    await this.assertMember(userId, groupId);
    const plan = await this.prisma.workoutPlan.findUnique({ where: { id: dto.workoutPlanId } });
    if (!plan || plan.userId !== userId) {
      throw new NotFoundException('Workout plan not found.');
    }
    const shared = await this.prisma.trainerGroupSharedPlan.upsert({
      where: { groupId_workoutPlanId: { groupId, workoutPlanId: dto.workoutPlanId } },
      update: {},
      create: { groupId, workoutPlanId: dto.workoutPlanId, sharedById: userId },
    });
    return {
      id: shared.id,
      groupId: shared.groupId,
      workoutPlanId: shared.workoutPlanId,
      sharedById: shared.sharedById,
      createdAt: shared.createdAt,
    };
  }

  async listSharedPlans(userId: string, groupId: string) {
    await this.assertMember(userId, groupId);
    const shared = await this.prisma.trainerGroupSharedPlan.findMany({
      where: { groupId },
      orderBy: { createdAt: 'desc' },
      include: { workoutPlan: { select: { id: true, name: true, description: true } } },
    });
    return shared.map((s) => ({
      id: s.id,
      sharedById: s.sharedById,
      createdAt: s.createdAt,
      workoutPlan: s.workoutPlan,
    }));
  }

  async unsharePlan(userId: string, groupId: string, sharedPlanId: string): Promise<void> {
    const group = await this.findGroup(groupId);
    const shared = await this.prisma.trainerGroupSharedPlan.findUnique({
      where: { id: sharedPlanId },
    });
    if (!shared || shared.groupId !== groupId) {
      throw new NotFoundException('Shared plan not found.');
    }
    const canRemove = shared.sharedById === userId || group.ownerId === userId;
    if (!canRemove) {
      throw new ForbiddenException('Only the sharer or the group owner can remove a shared plan.');
    }
    await this.prisma.trainerGroupSharedPlan.delete({ where: { id: sharedPlanId } });
  }

  // --- Shared helpers -----------------------------------------------------

  private async findGroup(groupId: string) {
    const group = await this.prisma.trainerGroup.findUnique({ where: { id: groupId } });
    if (!group) throw new NotFoundException('Group not found.');
    return group;
  }

  private async assertMember(userId: string, groupId: string): Promise<void> {
    await this.findGroup(groupId);
    const membership = await this.prisma.trainerGroupMember.findUnique({
      where: { groupId_userId: { groupId, userId } },
    });
    if (!membership) {
      throw new NotFoundException('Group not found.');
    }
  }

  private async serializeGroup(groupId: string, viewerId: string) {
    const group = await this.prisma.trainerGroup.findUniqueOrThrow({
      where: { id: groupId },
      include: {
        members: {
          include: { user: { include: { communityProfile: true } } },
          orderBy: { joinedAt: 'asc' },
        },
      },
    });
    return {
      id: group.id,
      ownerId: group.ownerId,
      name: group.name,
      description: group.description,
      memberLimit: TRAINER_GROUP_MEMBER_LIMIT_FREE,
      isOwnGroup: group.ownerId === viewerId,
      createdAt: group.createdAt,
      members: group.members.map((m) => ({
        userId: m.userId,
        role: m.role,
        joinedAt: m.joinedAt,
        displayName: m.user.communityProfile?.displayName ?? null,
        avatarUrl: m.user.communityProfile?.avatarUrl ?? null,
      })),
    };
  }

  private serializeInvitation(invitation: {
    id: string;
    groupId: string;
    inviterId: string;
    inviteeId: string;
    status: TrainerGroupInvitationStatus;
    createdAt: Date;
  }) {
    return {
      id: invitation.id,
      groupId: invitation.groupId,
      inviterId: invitation.inviterId,
      inviteeId: invitation.inviteeId,
      status: invitation.status,
      createdAt: invitation.createdAt,
    };
  }
}
