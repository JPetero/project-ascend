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

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(state.group!.name),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Chat'),
              Tab(text: 'Members'),
              Tab(text: 'Shared plans'),
              Tab(text: 'Announcements'),
            ],
          ),
          actions: [
            if (state.group!.isExpanded && (isOwner || isModerator))
              IconButton(
                icon: const Icon(Icons.event_available_outlined),
                tooltip: 'Schedule a session',
                onPressed: _scheduleSession,
              ),
            if (isOwner || isModerator)
              IconButton(
                icon: const Icon(Icons.person_add_alt_1),
                onPressed: _inviteMember,
              ),
          ],
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
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
                canPost: isOwner || isModerator,
                isPosting: state.isPostingAnnouncement,
                onPost: _postAnnouncement,
              ),
            ],
          ),
        ),
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
