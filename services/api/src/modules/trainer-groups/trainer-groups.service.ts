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
  TRAINER_GROUP_MEMBER_LIMIT_PREMIUM,
  TRAINER_GROUP_OWNED_LIMIT_FREE,
  TRAINER_GROUP_OWNED_LIMIT_PREMIUM,
} from '../../common/policy/trainer-group-policy';
import {
  PaginationQueryDto,
  paginationArgs,
  paginationMeta,
} from '../../common/pagination/pagination-query.dto';
import { CapabilityService } from '../../common/entitlements/capability.service';
import { AppCapability } from '../../common/entitlements/capability.util';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateTrainerGroupAnnouncementDto } from './dto/create-trainer-group-announcement.dto';
import { CreateTrainerGroupDto } from './dto/create-trainer-group.dto';
import { InviteTrainerGroupMemberDto } from './dto/invite-trainer-group-member.dto';
import { SendTrainerGroupMessageDto } from './dto/send-trainer-group-message.dto';
import { SetTrainerGroupMemberRoleDto } from './dto/set-trainer-group-member-role.dto';
import { ShareTrainerGroupPlanDto } from './dto/share-trainer-group-plan.dto';

/**
 * Trainer groups — see schema.prisma's Trainer group comment and
 * packages/docs/product/user-scenario-bible.md Scenario 24. Free tier:
 * one owned group, a small member limit, text/image chat, shared
 * workout plans, invitations. Expanded tier (Build Session 9 Part 20):
 * larger limits, a MODERATOR role, and announcements, all gated on the
 * group OWNER's AppCapability.TRAINER_GROUPS_EXPANDED — a group's
 * "premium-ness" follows its owner's tier, not the acting member's, so
 * a MODERATOR in a Premium owner's group still gets expanded limits
 * even though they hold no subscription of their own. Scheduled
 * sessions (Build Session 10 Part 24) reuse the existing Joint Workout
 * Sessions system via resolveGroupSessionInvitees below rather than
 * duplicating it. Still not implemented: assignments — see
 * parking-lot.md.
 */
@Injectable()
export class TrainerGroupsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly capabilityService: CapabilityService,
  ) {}

  // --- Groups -----------------------------------------------------------

  async createGroup(userId: string, dto: CreateTrainerGroupDto) {
    const expanded = await this.isExpanded(userId);
    const ownedLimit = expanded
      ? TRAINER_GROUP_OWNED_LIMIT_PREMIUM
      : TRAINER_GROUP_OWNED_LIMIT_FREE;
    const ownedCount = await this.prisma.trainerGroup.count({ where: { ownerId: userId } });
    if (ownedCount >= ownedLimit) {
      throw new ForbiddenException(
        `You can own at most ${ownedLimit} group${ownedLimit === 1 ? '' : 's'}.`,
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
    await this.assertCanManageMembers(userId, group.ownerId, groupId);
    if (dto.inviteeUserId === userId) {
      throw new BadRequestException('You cannot invite yourself.');
    }
    const alreadyMember = await this.prisma.trainerGroupMember.findUnique({
      where: { groupId_userId: { groupId, userId: dto.inviteeUserId } },
    });
    if (alreadyMember) {
      throw new ConflictException('This person is already a member of the group.');
    }
    const memberLimit = await this.memberLimitFor(group.ownerId);
    const memberCount = await this.prisma.trainerGroupMember.count({ where: { groupId } });
    if (memberCount >= memberLimit) {
      throw new ForbiddenException(`This group is at its ${memberLimit}-member limit.`);
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

    const group = await this.findGroup(invitation.groupId);
    const memberLimit = await this.memberLimitFor(group.ownerId);
    const memberCount = await this.prisma.trainerGroupMember.count({
      where: { groupId: invitation.groupId },
    });
    if (memberCount >= memberLimit) {
      throw new ForbiddenException(`This group is now at its ${memberLimit}-member limit.`);
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
      const callerRole = await this.roleOf(userId, groupId);
      if (callerRole !== TrainerGroupMemberRole.MODERATOR) {
        throw new ForbiddenException(
          'Only the group owner or a moderator can remove another member.',
        );
      }
      // A moderator can remove a regular member but never another
      // moderator — only the owner can do that.
      const targetRole = await this.roleOf(targetUserId, groupId);
      if (targetRole !== TrainerGroupMemberRole.MEMBER) {
        throw new ForbiddenException('A moderator can only remove a regular member.');
      }
    }

    const membership = await this.prisma.trainerGroupMember.findUnique({
      where: { groupId_userId: { groupId, userId: targetUserId } },
    });
    if (!membership) throw new NotFoundException('This person is not a member of the group.');
    await this.prisma.trainerGroupMember.delete({ where: { id: membership.id } });
  }

  // --- Roles (Build Session 9 Part 20 — expanded tier) --------------------

  async setMemberRole(
    userId: string,
    groupId: string,
    targetUserId: string,
    dto: SetTrainerGroupMemberRoleDto,
  ) {
    const group = await this.findGroup(groupId);
    if (group.ownerId !== userId) {
      throw new ForbiddenException('Only the group owner can change a member’s role.');
    }
    if (targetUserId === group.ownerId) {
      throw new BadRequestException('The group owner’s role cannot be changed.');
    }
    if (!(await this.isExpanded(group.ownerId))) {
      throw new ForbiddenException('Distinct member roles require the expanded (Premium) tier.');
    }
    const membership = await this.prisma.trainerGroupMember.findUnique({
      where: { groupId_userId: { groupId, userId: targetUserId } },
    });
    if (!membership) throw new NotFoundException('This person is not a member of the group.');

    const role =
      dto.role === 'MODERATOR' ? TrainerGroupMemberRole.MODERATOR : TrainerGroupMemberRole.MEMBER;
    const updated = await this.prisma.trainerGroupMember.update({
      where: { id: membership.id },
      data: { role },
    });
    return { userId: updated.userId, role: updated.role };
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

  // --- Announcements (Build Session 9 Part 20 — expanded tier) -----------

  async postAnnouncement(userId: string, groupId: string, dto: CreateTrainerGroupAnnouncementDto) {
    const group = await this.findGroup(groupId);
    const role = await this.roleOf(userId, groupId);
    if (role !== TrainerGroupMemberRole.OWNER && role !== TrainerGroupMemberRole.MODERATOR) {
      throw new ForbiddenException('Only the group owner or a moderator can post an announcement.');
    }
    if (!(await this.isExpanded(group.ownerId))) {
      throw new ForbiddenException('Announcements require the expanded (Premium) tier.');
    }
    const announcement = await this.prisma.trainerGroupAnnouncement.create({
      data: { groupId, authorId: userId, body: dto.body },
    });
    return {
      id: announcement.id,
      groupId: announcement.groupId,
      authorId: announcement.authorId,
      body: announcement.body,
      createdAt: announcement.createdAt,
    };
  }

  async listAnnouncements(userId: string, groupId: string) {
    await this.assertMember(userId, groupId);
    const announcements = await this.prisma.trainerGroupAnnouncement.findMany({
      where: { groupId },
      orderBy: { createdAt: 'desc' },
    });
    return announcements.map((a) => ({
      id: a.id,
      groupId: a.groupId,
      authorId: a.authorId,
      body: a.body,
      createdAt: a.createdAt,
    }));
  }

  // --- Scheduled sessions (Build Session 10 Part 24 — expanded tier) -----

  /**
   * Resolves a group into the userIds a scheduled session should invite
   * — reused by JointWorkoutSessionsService rather than duplicating
   * group-membership/permission logic there. Only the owner or a
   * moderator may schedule for the whole group (same permission level
   * as postAnnouncement), and — like announcements and distinct roles
   * — this requires the owner's expanded (Premium) tier per Scenario
   * 24's Premium-future list. Group members are not required to
   * already be Friends of the caller: joining the group (accepting an
   * invitation) is itself the vetted, opt-in relationship that
   * JointWorkoutSessionsService normally gets from FriendsService, so
   * that check is intentionally skipped for group-sourced invitees.
   */
  async resolveGroupSessionInvitees(userId: string, groupId: string): Promise<string[]> {
    const group = await this.findGroup(groupId);
    const role = await this.roleOf(userId, groupId);
    if (role !== TrainerGroupMemberRole.OWNER && role !== TrainerGroupMemberRole.MODERATOR) {
      throw new ForbiddenException(
        'Only the group owner or a moderator can schedule a session for this group.',
      );
    }
    if (!(await this.isExpanded(group.ownerId))) {
      throw new ForbiddenException(
        'Scheduling a session for the whole group requires the expanded (Premium) tier.',
      );
    }
    const members = await this.prisma.trainerGroupMember.findMany({
      where: { groupId },
      select: { userId: true },
    });
    return members.map((m) => m.userId).filter((id) => id !== userId);
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

  private async assertCanManageMembers(
    userId: string,
    ownerId: string,
    groupId: string,
  ): Promise<void> {
    if (userId === ownerId) return;
    const role = await this.roleOf(userId, groupId);
    if (role !== TrainerGroupMemberRole.MODERATOR) {
      throw new ForbiddenException('Only the group owner or a moderator can invite members.');
    }
  }

  private async roleOf(userId: string, groupId: string): Promise<TrainerGroupMemberRole | null> {
    const membership = await this.prisma.trainerGroupMember.findUnique({
      where: { groupId_userId: { groupId, userId } },
    });
    return membership?.role ?? null;
  }

  /** Whether `ownerId` currently holds TRAINER_GROUPS_EXPANDED — read
   * fresh on every call, never cached, so an upgrade or downgrade takes
   * effect on the very next request. */
  private isExpanded(ownerId: string): Promise<boolean> {
    return this.capabilityService.hasCapabilityForUser(
      ownerId,
      AppCapability.TRAINER_GROUPS_EXPANDED,
    );
  }

  private async memberLimitFor(ownerId: string): Promise<number> {
    return (await this.isExpanded(ownerId))
      ? TRAINER_GROUP_MEMBER_LIMIT_PREMIUM
      : TRAINER_GROUP_MEMBER_LIMIT_FREE;
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
    const expanded = await this.isExpanded(group.ownerId);
    return {
      id: group.id,
      ownerId: group.ownerId,
      name: group.name,
      description: group.description,
      memberLimit: expanded ? TRAINER_GROUP_MEMBER_LIMIT_PREMIUM : TRAINER_GROUP_MEMBER_LIMIT_FREE,
      isExpanded: expanded,
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
