import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  NotificationType,
  TrainerGroupInvitationStatus,
  TrainerGroupMemberRole,
  WorkoutAssignmentStatus,
} from '@prisma/client';
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
import { NotificationsService } from '../notifications/notifications.service';
import { CreateTrainerGroupAnnouncementDto } from './dto/create-trainer-group-announcement.dto';
import { CreateTrainerGroupDto } from './dto/create-trainer-group.dto';
import { CreateTrainerGroupScheduledSessionDto } from './dto/create-trainer-group-scheduled-session.dto';
import { CreateWorkoutAssignmentDto } from './dto/create-workout-assignment.dto';
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
 * even though they hold no subscription of their own. resolveGroupSessionInvitees
 * below reuses Joint Workout Sessions for an ad-hoc "start now" group
 * session. Date/time-based bookings are a separate concept — see the
 * "Scheduled sessions" section (Build Session 12 Part 10) and
 * TrainerGroupScheduledSession's schema comment for why they're not the
 * same thing. Workout assignments (Build Session 12 Part 9) and the
 * trainer dashboard (Part 11) round out this service.
 */
@Injectable()
export class TrainerGroupsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly capabilityService: CapabilityService,
    private readonly notifications: NotificationsService,
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
    // Build Session 12 Part 18-21 — unlike Friends/Messages/Joint
    // Workouts, this had no block check at all: a blocked user could
    // still be invited into (or still invite) a trainer group. Same
    // "not found, not forbidden" posture as FriendsService.sendRequest —
    // never reveal that a block is the reason.
    const [blockedByInvitee, blockedByInviter] = await Promise.all([
      this.prisma.communityBlock.findUnique({
        where: { blockerId_blockedId: { blockerId: dto.inviteeUserId, blockedId: userId } },
      }),
      this.prisma.communityBlock.findUnique({
        where: { blockerId_blockedId: { blockerId: userId, blockedId: dto.inviteeUserId } },
      }),
    ]);
    if (blockedByInvitee || blockedByInviter) {
      throw new NotFoundException('User not found.');
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

  // --- Workout assignments (Build Session 12 Part 9) ----------------------

  async createAssignments(userId: string, groupId: string, dto: CreateWorkoutAssignmentDto) {
    const group = await this.findGroup(groupId);
    await this.assertCanManageMembers(userId, group.ownerId, groupId);

    const plan = await this.prisma.workoutPlan.findUnique({ where: { id: dto.workoutPlanId } });
    if (!plan || plan.userId !== userId) {
      throw new NotFoundException('Workout plan not found.');
    }

    const uniqueAssignees = Array.from(new Set(dto.assigneeUserIds));
    const members = await this.prisma.trainerGroupMember.findMany({
      where: { groupId, userId: { in: uniqueAssignees } },
      select: { userId: true },
    });
    const memberIds = new Set(members.map((m) => m.userId));
    if (uniqueAssignees.some((id) => !memberIds.has(id))) {
      throw new BadRequestException('Every assignee must be a member of this group.');
    }

    const assignments = await Promise.all(
      uniqueAssignees.map((assigneeId) =>
        this.prisma.workoutAssignment.create({
          data: {
            groupId,
            assignedById: userId,
            assigneeId,
            sourcePlanId: dto.workoutPlanId,
            note: dto.note,
            dueAt: dto.dueAt ? new Date(dto.dueAt) : undefined,
          },
        }),
      ),
    );

    await Promise.all(
      assignments.map((a) =>
        this.notifications.notify(
          a.assigneeId,
          NotificationType.WORKOUT_ASSIGNED,
          'New workout assigned',
          `"${plan.name}" was assigned to you.`,
          a.id,
        ),
      ),
    );

    return assignments.map((a) => this.serializeAssignment(a, plan.name));
  }

  async listGroupAssignments(userId: string, groupId: string) {
    const group = await this.findGroup(groupId);
    await this.assertCanManageMembers(userId, group.ownerId, groupId);
    const assignments = await this.prisma.workoutAssignment.findMany({
      where: { groupId },
      orderBy: { createdAt: 'desc' },
      include: { sourcePlan: { select: { name: true } } },
    });
    return assignments.map((a) => this.serializeAssignment(a, a.sourcePlan.name));
  }

  async listMyAssignments(userId: string) {
    const assignments = await this.prisma.workoutAssignment.findMany({
      where: { assigneeId: userId },
      orderBy: { createdAt: 'desc' },
      include: { sourcePlan: { select: { name: true } } },
    });
    return assignments.map((a) => this.serializeAssignment(a, a.sourcePlan.name));
  }

  /**
   * Accepting clones the trainer's source plan's exercises into a
   * brand-new WorkoutPlan owned by the assignee — the same "own copy,
   * unaffected by later edits" approach WorkoutPlan.workoutId already
   * uses for catalog-based plans — rather than loosening
   * WorkoutSessionsService's ownership check. The returned
   * `workoutPlanId` is a normal plan the assignee can immediately start
   * a session against via the existing `POST /workout-sessions` flow.
   */
  async acceptAssignment(userId: string, assignmentId: string) {
    const assignment = await this.prisma.workoutAssignment.findUnique({
      where: { id: assignmentId },
      include: { sourcePlan: { include: { exercises: true } } },
    });
    if (!assignment || assignment.assigneeId !== userId) {
      throw new NotFoundException('Assignment not found.');
    }
    if (assignment.status !== WorkoutAssignmentStatus.PENDING) {
      throw new ConflictException('This assignment has already been responded to.');
    }

    const clonedPlan = await this.prisma.$transaction(async (tx) => {
      const plan = await tx.workoutPlan.create({
        data: {
          userId,
          name: assignment.sourcePlan.name,
          description: assignment.sourcePlan.description,
        },
      });
      if (assignment.sourcePlan.exercises.length > 0) {
        await tx.workoutPlanExercise.createMany({
          data: assignment.sourcePlan.exercises.map((e) => ({
            workoutPlanId: plan.id,
            exerciseId: e.exerciseId,
            order: e.order,
            targetSets: e.targetSets,
            targetReps: e.targetReps,
            targetDurationSeconds: e.targetDurationSeconds,
            targetWeightKg: e.targetWeightKg,
            targetDistanceMeters: e.targetDistanceMeters,
            restSeconds: e.restSeconds,
            notes: e.notes,
          })),
        });
      }
      await tx.workoutAssignment.update({
        where: { id: assignmentId },
        data: { status: WorkoutAssignmentStatus.ACCEPTED, assignedPlanId: plan.id },
      });
      return plan;
    });

    return { assignmentId, workoutPlanId: clonedPlan.id };
  }

  async cancelAssignment(userId: string, assignmentId: string): Promise<void> {
    const assignment = await this.prisma.workoutAssignment.findUnique({
      where: { id: assignmentId },
    });
    if (!assignment) throw new NotFoundException('Assignment not found.');
    const canCancel = assignment.assignedById === userId || assignment.assigneeId === userId;
    if (!canCancel) {
      throw new ForbiddenException('Only the assigner or the assignee can remove this assignment.');
    }
    if (assignment.status === WorkoutAssignmentStatus.COMPLETED) {
      throw new ConflictException('A completed assignment cannot be removed.');
    }
    await this.prisma.workoutAssignment.delete({ where: { id: assignmentId } });
  }

  /**
   * Called from WorkoutSessionsService.finish() so an assignment
   * resolves itself the moment the assignee completes a session against
   * its cloned plan — never something either party has to remember to
   * mark by hand. A no-op (never throws) when `workoutPlanId` doesn't
   * match any of the caller's accepted assignments, which is the
   * common case for an ordinary, non-assigned workout.
   */
  async completeAssignmentsForSession(userId: string, workoutPlanId: string | null): Promise<void> {
    if (!workoutPlanId) return;
    await this.prisma.workoutAssignment.updateMany({
      where: {
        assigneeId: userId,
        assignedPlanId: workoutPlanId,
        status: WorkoutAssignmentStatus.ACCEPTED,
      },
      data: { status: WorkoutAssignmentStatus.COMPLETED, completedAt: new Date() },
    });
  }

  // --- Scheduled sessions (Build Session 12 Part 10 — expanded tier) ------

  async createScheduledSession(
    userId: string,
    groupId: string,
    dto: CreateTrainerGroupScheduledSessionDto,
  ) {
    const group = await this.findGroup(groupId);
    await this.assertCanManageMembers(userId, group.ownerId, groupId);
    if (!(await this.isExpanded(group.ownerId))) {
      throw new ForbiddenException('Scheduling a session requires the expanded (Premium) tier.');
    }
    const scheduledAt = new Date(dto.scheduledAt);
    if (Number.isNaN(scheduledAt.getTime()) || scheduledAt.getTime() <= Date.now()) {
      throw new BadRequestException('scheduledAt must be a valid time in the future.');
    }

    const session = await this.prisma.trainerGroupScheduledSession.create({
      data: {
        groupId,
        createdById: userId,
        title: dto.title,
        scheduledAt,
        durationMinutes: dto.durationMinutes,
        location: dto.location,
        videoLink: dto.videoLink,
        description: dto.description,
      },
    });

    const members = await this.prisma.trainerGroupMember.findMany({
      where: { groupId, userId: { not: userId } },
      select: { userId: true },
    });
    await Promise.all(
      members.map((m) =>
        this.notifications.notify(
          m.userId,
          NotificationType.GROUP_SESSION_SCHEDULED,
          'New session scheduled',
          `${group.name} has a new scheduled session.`,
          session.id,
        ),
      ),
    );

    return this.serializeScheduledSession(session);
  }

  async listScheduledSessions(userId: string, groupId: string) {
    await this.assertMember(userId, groupId);
    const sessions = await this.prisma.trainerGroupScheduledSession.findMany({
      where: { groupId, canceledAt: null },
      orderBy: { scheduledAt: 'asc' },
    });
    return sessions.map((s) => this.serializeScheduledSession(s));
  }

  async cancelScheduledSession(userId: string, sessionId: string): Promise<void> {
    const session = await this.prisma.trainerGroupScheduledSession.findUnique({
      where: { id: sessionId },
    });
    if (!session) throw new NotFoundException('Scheduled session not found.');
    const group = await this.findGroup(session.groupId);
    const canCancel = session.createdById === userId || group.ownerId === userId;
    if (!canCancel) {
      throw new ForbiddenException('Only the creator or the group owner can cancel this session.');
    }
    if (session.canceledAt) {
      throw new ConflictException('This session is already canceled.');
    }
    await this.prisma.trainerGroupScheduledSession.update({
      where: { id: sessionId },
      data: { canceledAt: new Date() },
    });
  }

  // --- Trainer dashboard (Build Session 12 Part 11) ------------------------

  /**
   * A read-only aggregate across every group the caller owns or
   * moderates — memberCount and pending-assignment count per group, plus
   * the whole roster's soonest upcoming scheduled sessions and most
   * recent assignments. No new write model: everything here composes
   * existing membership/assignment/scheduled-session rows.
   */
  async getTrainerDashboard(userId: string) {
    const memberships = await this.prisma.trainerGroupMember.findMany({
      where: {
        userId,
        role: { in: [TrainerGroupMemberRole.OWNER, TrainerGroupMemberRole.MODERATOR] },
      },
      select: { groupId: true },
    });
    const groupIds = memberships.map((m) => m.groupId);
    if (groupIds.length === 0) {
      return { groups: [], upcomingSessions: [], recentAssignments: [] };
    }

    const [groups, upcomingSessions, recentAssignments, pendingCounts] = await Promise.all([
      this.prisma.trainerGroup.findMany({
        where: { id: { in: groupIds } },
        include: { _count: { select: { members: true } } },
      }),
      this.prisma.trainerGroupScheduledSession.findMany({
        where: { groupId: { in: groupIds }, canceledAt: null, scheduledAt: { gte: new Date() } },
        orderBy: { scheduledAt: 'asc' },
        take: 10,
      }),
      this.prisma.workoutAssignment.findMany({
        where: { groupId: { in: groupIds } },
        orderBy: { createdAt: 'desc' },
        take: 10,
        include: { sourcePlan: { select: { name: true } } },
      }),
      this.prisma.workoutAssignment.groupBy({
        by: ['groupId'],
        where: { groupId: { in: groupIds }, status: WorkoutAssignmentStatus.PENDING },
        _count: { _all: true },
      }),
    ]);

    const pendingByGroup = new Map(pendingCounts.map((p) => [p.groupId, p._count._all]));

    return {
      groups: groups.map((g) => ({
        id: g.id,
        name: g.name,
        memberCount: g._count.members,
        pendingAssignmentCount: pendingByGroup.get(g.id) ?? 0,
      })),
      upcomingSessions: upcomingSessions.map((s) => this.serializeScheduledSession(s)),
      recentAssignments: recentAssignments.map((a) =>
        this.serializeAssignment(a, a.sourcePlan.name),
      ),
    };
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

  private serializeAssignment(
    a: {
      id: string;
      groupId: string;
      assignedById: string;
      assigneeId: string;
      sourcePlanId: string;
      assignedPlanId: string | null;
      note: string | null;
      dueAt: Date | null;
      status: WorkoutAssignmentStatus;
      createdAt: Date;
      completedAt: Date | null;
    },
    sourcePlanName: string,
  ) {
    return {
      id: a.id,
      groupId: a.groupId,
      assignedById: a.assignedById,
      assigneeId: a.assigneeId,
      sourcePlanId: a.sourcePlanId,
      sourcePlanName,
      assignedPlanId: a.assignedPlanId,
      note: a.note,
      dueAt: a.dueAt,
      status: a.status,
      createdAt: a.createdAt,
      completedAt: a.completedAt,
    };
  }

  private serializeScheduledSession(s: {
    id: string;
    groupId: string;
    createdById: string;
    title: string | null;
    scheduledAt: Date;
    durationMinutes: number | null;
    location: string | null;
    videoLink: string | null;
    description: string | null;
    canceledAt: Date | null;
    createdAt: Date;
  }) {
    return {
      id: s.id,
      groupId: s.groupId,
      createdById: s.createdById,
      title: s.title,
      scheduledAt: s.scheduledAt,
      durationMinutes: s.durationMinutes,
      location: s.location,
      videoLink: s.videoLink,
      description: s.description,
      canceledAt: s.canceledAt,
      createdAt: s.createdAt,
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
