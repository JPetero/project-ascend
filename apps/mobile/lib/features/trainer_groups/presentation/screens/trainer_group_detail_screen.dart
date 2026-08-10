import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../joint_workouts/presentation/providers/joint_workout_sessions_controller.dart';
import '../../../workout/presentation/providers/workout_plan_controller.dart';
import '../../domain/trainer_group.dart';
import '../providers/trainer_group_detail_controller.dart';

class TrainerGroupDetailScreen extends ConsumerStatefulWidget {
  const TrainerGroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<TrainerGroupDetailScreen> createState() =>
      _TrainerGroupDetailScreenState();
}

class _TrainerGroupDetailScreenState
    extends ConsumerState<TrainerGroupDetailScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final controller = ref.read(
      trainerGroupDetailControllerProvider(widget.groupId).notifier,
    );
    final body = _messageController.text;
    _messageController.clear();
    final sent = await controller.sendMessage(body: body);
    if (!sent) _messageController.text = body;
  }

  Future<void> _inviteMember() async {
    final controller = ref.read(
      trainerGroupDetailControllerProvider(widget.groupId).notifier,
    );
    final userIdController = TextEditingController();
    final userId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite a member'),
        content: TextField(
          controller: userIdController,
          decoration: const InputDecoration(
            labelText: 'Their user ID',
            helperText:
                'From their Community profile for now — no user search yet.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, userIdController.text.trim()),
            child: const Text('Invite'),
          ),
        ],
      ),
    );
    if (userId == null || userId.isEmpty) return;
    final ok = await controller.invite(userId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Invitation sent.' : "Couldn't invite — try again."),
      ),
    );
  }

  Future<void> _postAnnouncement() async {
    final controller = ref.read(
      trainerGroupDetailControllerProvider(widget.groupId).notifier,
    );
    final bodyController = TextEditingController();
    final body = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post an announcement'),
        content: TextField(
          controller: bodyController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: "What's the news?"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, bodyController.text.trim()),
            child: const Text('Post'),
          ),
        ],
      ),
    );
    if (body == null || body.isEmpty) return;
    final ok = await controller.postAnnouncement(body);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Announcement posted.' : "Couldn't post — try again.",
        ),
      ),
    );
  }

  Future<void> _sharePlan() async {
    final controller = ref.read(
      trainerGroupDetailControllerProvider(widget.groupId).notifier,
    );
    final plans = await ref.read(workoutPlanRepositoryProvider).list();
    if (!mounted) return;
    if (plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a workout plan first to share one here.'),
        ),
      );
      return;
    }
    final planId = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Share a plan'),
        children: [
          for (final plan in plans)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, plan.id),
              child: Text(plan.name),
            ),
        ],
      ),
    );
    if (planId == null) return;
    final ok = await controller.sharePlan(planId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Plan shared.' : "Couldn't share — try again."),
      ),
    );
  }

  /// Owner/moderator-only (Build Session 12 Part 9) — picks one of the
  /// caller's own workout plans and one or more group members to assign
  /// it to. See TrainerGroupsService.createAssignments for the
  /// membership validation and clone-on-accept flow.
  Future<void> _assignWorkout() async {
    final controller = ref.read(
      trainerGroupDetailControllerProvider(widget.groupId).notifier,
    );
    final group = ref.read(
      trainerGroupDetailControllerProvider(
        widget.groupId,
      ).select((s) => s.group),
    );
    if (group == null) return;
    final plans = await ref.read(workoutPlanRepositoryProvider).list();
    if (!mounted) return;
    if (plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a workout plan first to assign one.'),
        ),
      );
      return;
    }
    final planId = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Assign which plan?'),
        children: [
          for (final plan in plans)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, plan.id),
              child: Text(plan.name),
            ),
        ],
      ),
    );
    if (planId == null || !mounted) return;

    final assignees = <String>{};
    final noteController = TextEditingController();
    DateTime? dueAt;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Assign to whom?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final member in group.members)
                  if (member.userId != group.ownerId)
                    CheckboxListTile(
                      value: assignees.contains(member.userId),
                      title: Text(member.displayName ?? 'Ascend member'),
                      onChanged: (checked) => setState(() {
                        if (checked ?? false) {
                          assignees.add(member.userId);
                        } else {
                          assignees.remove(member.userId);
                        }
                      }),
                    ),
                const SizedBox(height: AscendSpacing.sm),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note — optional',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AscendSpacing.sm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    dueAt == null
                        ? 'No due date'
                        : 'Due ${dueAt!.toLocal().toString().split(' ').first}',
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => dueAt = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: assignees.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await controller.createAssignments(
      workoutPlanId: planId,
      assigneeUserIds: assignees.toList(),
      note: noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim(),
      dueAt: dueAt,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Workout assigned.' : "Couldn't assign — try again.",
        ),
      ),
    );
  }

  /// Owner/moderator + the group owner's expanded (Premium) tier (Build
  /// Session 12 Part 10) — a genuine date/time booking, distinct from
  /// the ad-hoc "start now" Joint Workout Session scheduled above. See
  /// TrainerGroupScheduledSession's schema comment.
  Future<void> _scheduleDatedSession() async {
    final controller = ref.read(
      trainerGroupDetailControllerProvider(widget.groupId).notifier,
    );
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );
    if (time == null || !mounted) return;
    final scheduledAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final titleController = TextEditingController();
    final videoLinkController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Session details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title (optional)'),
            ),
            TextField(
              controller: videoLinkController,
              decoration: const InputDecoration(
                labelText: 'Video link (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await controller.createScheduledSession(
      scheduledAt: scheduledAt,
      title: titleController.text.trim().isEmpty
          ? null
          : titleController.text.trim(),
      videoLink: videoLinkController.text.trim().isEmpty
          ? null
          : videoLinkController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Session scheduled.' : "Couldn't schedule — try again.",
        ),
      ),
    );
  }

  /// Schedules a Joint Workout Session for every current group member —
  /// Build Session 10 Part 24, reusing the existing friend-only Joint
  /// Workout Sessions system (via `trainerGroupId`) rather than
  /// duplicating it. Same owner/moderator + expanded-tier gate as
  /// announcements, enforced server-side by
  /// TrainerGroupsService.resolveGroupSessionInvitees.
  Future<void> _scheduleSession() async {
    final titleController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Schedule a group session'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Title (optional)',
            hintText: 'e.g. Saturday squad session',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final session = await ref
        .read(jointWorkoutSessionsControllerProvider.notifier)
        .create(
          title: titleController.text.trim().isEmpty
              ? null
              : titleController.text.trim(),
          trainerGroupId: widget.groupId,
        );
    if (!mounted) return;
    if (session != null) {
      context.push(RoutePaths.jointWorkoutDetailPath(session.id));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't schedule the session — try again."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      trainerGroupDetailControllerProvider(widget.groupId),
    );
    final controller = ref.read(
      trainerGroupDetailControllerProvider(widget.groupId).notifier,
    );
    final viewerId = ref.watch(
      authControllerProvider.select((s) => s.user?.id),
    );
    final isOwner = state.group?.ownerId == viewerId;
    TrainerGroupMemberRole? viewerRole;
    for (final member in state.group?.members ?? const <TrainerGroupMember>[]) {
      if (member.userId == viewerId) {
        viewerRole = member.role;
        break;
      }
    }
    final isModerator = viewerRole == TrainerGroupMemberRole.moderator;

    if (state.isLoading) {
      return const Scaffold(body: SafeArea(child: AscendLoadingIndicator()));
    }
    if (state.group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group')),
        body: SafeArea(
          child: AscendEmptyState(
            icon: Icons.error_outline,
            title: "Couldn't load this group",
            message:
                state.error ??
                'It may have been deleted, or you are no longer a member.',
          ),
        ),
      );
    }

    final canManage = isOwner || isModerator;
    final tabs = <Tab>[
      const Tab(text: 'Chat'),
      const Tab(text: 'Members'),
      const Tab(text: 'Shared plans'),
      const Tab(text: 'Announcements'),
      const Tab(text: 'Scheduled'),
      if (canManage) const Tab(text: 'Assignments'),
    ];
    final tabViews = <Widget>[
      _ChatTab(
        state: state,
        messageController: _messageController,
        onSend: _sendMessage,
        viewerId: viewerId,
      ),
      _MembersTab(
        group: state.group!,
        viewerId: viewerId,
        isOwner: isOwner,
        onRemove: controller.removeMember,
        onSetRole: controller.setMemberRole,
      ),
      _SharedPlansTab(
        sharedPlans: state.sharedPlans,
        viewerId: viewerId,
        isOwner: isOwner,
        onShare: _sharePlan,
        onUnshare: controller.unsharePlan,
      ),
      _AnnouncementsTab(
        announcements: state.announcements,
        isExpanded: state.group!.isExpanded,
        canPost: canManage,
        isPosting: state.isPostingAnnouncement,
        onPost: _postAnnouncement,
      ),
      _ScheduledSessionsTab(
        sessions: state.scheduledSessions,
        canManage: canManage,
        isExpanded: state.group!.isExpanded,
        viewerId: viewerId,
        onSchedule: _scheduleDatedSession,
        onCancel: controller.cancelScheduledSession,
        onRsvp: controller.rsvpToScheduledSession,
        onCancelRsvp: controller.cancelMyRsvp,
      ),
      if (canManage)
        _AssignmentsTab(
          assignments: state.assignments,
          members: state.group!.members,
          onAssign: _assignWorkout,
          onCancel: controller.cancelAssignment,
        ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(state.group!.name),
          bottom: TabBar(isScrollable: true, tabs: tabs),
          actions: [
            if (canManage)
              IconButton(
                icon: const Icon(Icons.assignment_ind_outlined),
                tooltip: 'Assign a workout',
                onPressed: _assignWorkout,
              ),
            if (state.group!.isExpanded && canManage)
              IconButton(
                icon: const Icon(Icons.event_available_outlined),
                tooltip: 'Start a group session now',
                onPressed: _scheduleSession,
              ),
            if (canManage)
              IconButton(
                icon: const Icon(Icons.person_add_alt_1),
                tooltip: 'Invite member',
                onPressed: _inviteMember,
              ),
          ],
        ),
        body: SafeArea(child: TabBarView(children: tabViews)),
      ),
    );
  }
}

class _ChatTab extends StatelessWidget {
  const _ChatTab({
    required this.state,
    required this.messageController,
    required this.onSend,
    required this.viewerId,
  });

  final TrainerGroupDetailState state;
  final TextEditingController messageController;
  final Future<void> Function() onSend;
  final String? viewerId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: state.messages.isEmpty
              ? const AscendEmptyState(
                  icon: Icons.forum_outlined,
                  title: 'No messages yet',
                  message: 'Say hello to the group.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AscendSpacing.md),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    final isMine = message.authorId == viewerId;
                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: AscendSpacing.xs,
                        ),
                        padding: const EdgeInsets.all(AscendSpacing.sm),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMine
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            AscendRadius.medium,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.imageUrl != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AscendSpacing.xs,
                                ),
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            if (message.body != null) Text(message.body!),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(AscendSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    hintText: 'Message the group…',
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                ),
              ),
              IconButton(
                icon: state.isSendingMessage
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                onPressed: state.isSendingMessage ? null : onSend,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MembersTab extends StatelessWidget {
  const _MembersTab({
    required this.group,
    required this.viewerId,
    required this.isOwner,
    required this.onRemove,
    required this.onSetRole,
  });

  final TrainerGroup group;
  final String? viewerId;
  final bool isOwner;
  final Future<bool> Function(String userId) onRemove;
  final Future<bool> Function(String userId, TrainerGroupMemberRole role)
  onSetRole;

  String _roleLabel(TrainerGroupMemberRole role) {
    switch (role) {
      case TrainerGroupMemberRole.owner:
        return 'Owner';
      case TrainerGroupMemberRole.moderator:
        return 'Moderator';
      case TrainerGroupMemberRole.member:
        return 'Member';
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = group.members;
    return ListView(
      padding: const EdgeInsets.all(AscendSpacing.md),
      children: [
        // Distinct trainer/moderator roles are an expanded (Premium)
        // capability — see TrainerGroup.isExpanded.
        if (isOwner && !group.isExpanded)
          const Padding(
            padding: EdgeInsets.only(bottom: AscendSpacing.sm),
            child: Text(
              'Upgrade to Premium to assign a moderator to help run this group.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        for (final member in members)
          ListTile(
            leading: CircleAvatar(
              backgroundImage: member.avatarUrl != null
                  ? NetworkImage(member.avatarUrl!)
                  : null,
              child: member.avatarUrl == null
                  ? const Icon(Icons.person_outline)
                  : null,
            ),
            title: Text(member.displayName ?? 'Ascend member'),
            subtitle: Text(_roleLabel(member.role)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isOwner &&
                    group.isExpanded &&
                    member.role != TrainerGroupMemberRole.owner)
                  IconButton(
                    icon: Icon(
                      member.role == TrainerGroupMemberRole.moderator
                          ? Icons.remove_moderator_outlined
                          : Icons.add_moderator_outlined,
                    ),
                    tooltip: member.role == TrainerGroupMemberRole.moderator
                        ? 'Remove as moderator'
                        : 'Make moderator',
                    onPressed: () => onSetRole(
                      member.userId,
                      member.role == TrainerGroupMemberRole.moderator
                          ? TrainerGroupMemberRole.member
                          : TrainerGroupMemberRole.moderator,
                    ),
                  ),
                if ((isOwner && member.role != TrainerGroupMemberRole.owner) ||
                    member.userId == viewerId)
                  IconButton(
                    icon: Icon(
                      member.userId == viewerId
                          ? Icons.exit_to_app
                          : Icons.person_remove_outlined,
                    ),
                    tooltip: member.userId == viewerId
                        ? 'Leave group'
                        : 'Remove member',
                    onPressed: () => onRemove(member.userId),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AnnouncementsTab extends StatelessWidget {
  const _AnnouncementsTab({
    required this.announcements,
    required this.isExpanded,
    required this.canPost,
    required this.isPosting,
    required this.onPost,
  });

  final List<TrainerGroupAnnouncement> announcements;
  final bool isExpanded;
  final bool canPost;
  final bool isPosting;
  final Future<void> Function() onPost;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: !isExpanded
              ? const AscendEmptyState(
                  icon: Icons.campaign_outlined,
                  title: 'Announcements are a Premium feature',
                  message:
                      'Upgrade to Premium to post group-wide announcements.',
                )
              : announcements.isEmpty
              ? const AscendEmptyState(
                  icon: Icons.campaign_outlined,
                  title: 'No announcements yet',
                  message: 'The owner or a moderator can post one here.',
                )
              : ListView(
                  padding: const EdgeInsets.all(AscendSpacing.md),
                  children: [
                    for (final announcement in announcements)
                      AscendCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(announcement.body),
                            const SizedBox(height: AscendSpacing.xs),
                            Text(
                              announcement.createdAt.toLocal().toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        if (isExpanded && canPost)
          Padding(
            padding: const EdgeInsets.all(AscendSpacing.md),
            child: AscendSecondaryButton(
              label: 'Post an announcement',
              isLoading: isPosting,
              onPressed: onPost,
            ),
          ),
      ],
    );
  }
}

class _SharedPlansTab extends StatelessWidget {
  const _SharedPlansTab({
    required this.sharedPlans,
    required this.viewerId,
    required this.isOwner,
    required this.onShare,
    required this.onUnshare,
  });

  final List<TrainerGroupSharedPlan> sharedPlans;
  final String? viewerId;
  final bool isOwner;
  final Future<void> Function() onShare;
  final Future<bool> Function(String sharedPlanId) onUnshare;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: sharedPlans.isEmpty
              ? const AscendEmptyState(
                  icon: Icons.fitness_center_outlined,
                  title: 'No shared plans yet',
                  message:
                      'Share one of your own workout plans with the group.',
                )
              : ListView(
                  padding: const EdgeInsets.all(AscendSpacing.md),
                  children: [
                    for (final shared in sharedPlans)
                      AscendCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shared.workoutPlanName,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  if (shared.workoutPlanDescription != null)
                                    Text(
                                      shared.workoutPlanDescription!,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                            if (isOwner || shared.sharedById == viewerId)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                tooltip: 'Remove',
                                onPressed: () => onUnshare(shared.id),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(AscendSpacing.md),
          child: AscendSecondaryButton(
            label: 'Share a plan',
            onPressed: onShare,
          ),
        ),
      ],
    );
  }
}

/// Build Session 12 Part 10 — a genuine date/time booking, visible to
/// every member; only the owner/moderator can add one, and only on an
/// expanded (Premium) group.
class _ScheduledSessionsTab extends StatelessWidget {
  const _ScheduledSessionsTab({
    required this.sessions,
    required this.canManage,
    required this.isExpanded,
    required this.viewerId,
    required this.onSchedule,
    required this.onCancel,
    required this.onRsvp,
    required this.onCancelRsvp,
  });

  final List<TrainerGroupScheduledSession> sessions;
  final bool canManage;
  final bool isExpanded;
  final String? viewerId;
  final Future<void> Function() onSchedule;
  final Future<bool> Function(String sessionId) onCancel;
  final Future<bool> Function(
    String sessionId,
    ScheduledSessionRsvpStatus status,
  )
  onRsvp;
  final Future<bool> Function(String sessionId) onCancelRsvp;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: sessions.isEmpty
              ? const AscendEmptyState(
                  icon: Icons.event_outlined,
                  title: 'No sessions scheduled',
                  message: 'The owner or a moderator can book one here.',
                )
              : ListView(
                  padding: const EdgeInsets.all(AscendSpacing.md),
                  children: [
                    for (final session in sessions)
                      AscendCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        session.title ?? 'Group session',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      Text(
                                        session.scheduledAt
                                            .toLocal()
                                            .toString(),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      if (session.workoutPlanName != null)
                                        Text(
                                          'Plan: ${session.workoutPlanName}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      if (session.videoLink != null)
                                        Text(
                                          session.videoLink!,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      Text(
                                        'Going ${session.goingCount} · '
                                        'Maybe ${session.maybeCount} · '
                                        'Can\'t go ${session.declinedCount}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                if (canManage ||
                                    session.createdById == viewerId)
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    tooltip: 'Cancel',
                                    onPressed: () => onCancel(session.id),
                                  ),
                              ],
                            ),
                            if (session.status ==
                                ScheduledSessionStatus.upcoming)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AscendSpacing.sm,
                                ),
                                child: Wrap(
                                  spacing: AscendSpacing.sm,
                                  children: [
                                    for (final option in const [
                                      (
                                        ScheduledSessionRsvpStatus.going,
                                        'Going',
                                      ),
                                      (
                                        ScheduledSessionRsvpStatus.maybe,
                                        'Maybe',
                                      ),
                                      (
                                        ScheduledSessionRsvpStatus.declined,
                                        "Can't go",
                                      ),
                                    ])
                                      ChoiceChip(
                                        label: Text(option.$2),
                                        selected:
                                            session.viewerRsvpStatus ==
                                            option.$1,
                                        onSelected: (selected) {
                                          if (selected) {
                                            onRsvp(session.id, option.$1);
                                          } else {
                                            onCancelRsvp(session.id);
                                          }
                                        },
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        if (canManage && isExpanded)
          Padding(
            padding: const EdgeInsets.all(AscendSpacing.md),
            child: AscendSecondaryButton(
              label: 'Schedule a session',
              onPressed: onSchedule,
            ),
          ),
      ],
    );
  }
}

/// Owner/moderator-only (Build Session 12 Part 9) — a trainer's view of
/// every workout assigned to this group's members, whatever its status.
class _AssignmentsTab extends StatelessWidget {
  const _AssignmentsTab({
    required this.assignments,
    required this.members,
    required this.onAssign,
    required this.onCancel,
  });

  final List<WorkoutAssignment> assignments;
  final List<TrainerGroupMember> members;
  final Future<void> Function() onAssign;
  final Future<bool> Function(String assignmentId) onCancel;

  String _assigneeLabel(String assigneeId) {
    for (final member in members) {
      if (member.userId == assigneeId) {
        return member.displayName ?? 'Ascend member';
      }
    }
    return 'Ascend member';
  }

  String _statusLabel(WorkoutAssignmentStatus status) {
    switch (status) {
      case WorkoutAssignmentStatus.pending:
        return 'Pending';
      case WorkoutAssignmentStatus.accepted:
        return 'In progress';
      case WorkoutAssignmentStatus.declined:
        return 'Declined';
      case WorkoutAssignmentStatus.completed:
        return 'Completed';
      case WorkoutAssignmentStatus.canceled:
        return 'Canceled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: assignments.isEmpty
              ? const AscendEmptyState(
                  icon: Icons.assignment_ind_outlined,
                  title: 'No workouts assigned yet',
                  message: 'Assign one of your workout plans to a member.',
                )
              : ListView(
                  padding: const EdgeInsets.all(AscendSpacing.md),
                  children: [
                    for (final assignment in assignments)
                      AscendCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    assignment.sourcePlanName,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  Text(
                                    '${_assigneeLabel(assignment.assigneeId)} · '
                                    '${assignment.isOverdue ? "Overdue" : _statusLabel(assignment.status)}'
                                    '${assignment.dueAt != null ? " · Due ${assignment.dueAt!.toLocal().toString().split(' ').first}" : ''}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: assignment.isOverdue
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.error
                                              : null,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (assignment.status !=
                                WorkoutAssignmentStatus.completed)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                tooltip: 'Remove',
                                onPressed: () => onCancel(assignment.id),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(AscendSpacing.md),
          child: AscendSecondaryButton(
            label: 'Assign a workout',
            onPressed: onAssign,
          ),
        ),
      ],
    );
  }
}
