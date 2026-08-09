import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/community_post.dart';
import '../../domain/community_profile.dart';
import '../providers/community_feed_controller.dart';
import '../providers/community_profile_controller.dart';
import '../widgets/community_post_list_view.dart';

class CommunityProfileScreen extends ConsumerWidget {
  const CommunityProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewerId = ref.watch(
      authControllerProvider.select((s) => s.user?.id),
    );
    final isOwnProfile = viewerId == userId;
    final profileState = ref.watch(communityProfileControllerProvider(userId));
    final profileController = ref.read(
      communityProfileControllerProvider(userId).notifier,
    );
    final feedState = ref.watch(communityFeedControllerProvider(userId));
    final feedController = ref.read(
      communityFeedControllerProvider(userId).notifier,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community profile'),
        actions: [
          if (isOwnProfile) ...[
            IconButton(
              icon: const Icon(Icons.insights_outlined),
              tooltip: 'My content performance',
              onPressed: () =>
                  context.push(RoutePaths.communityContentAnalytics),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit profile',
              onPressed: () async {
                await context.push(RoutePaths.communityEditProfile);
                profileController.load();
              },
            ),
          ] else if (profileState.profile != null)
            PopupMenuButton<String>(
              onSelected: (action) => _handleAction(context, ref, action),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'block', child: Text('Block')),
                PopupMenuItem(value: 'report', child: Text('Report')),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: profileState.isLoading
            ? const AscendLoadingIndicator()
            : profileState.profile == null
            ? AscendEmptyState(
                icon: isOwnProfile
                    ? Icons.person_add_alt_outlined
                    : Icons.person_off_outlined,
                title: isOwnProfile
                    ? 'Set up your Community profile'
                    : 'Profile not found',
                message: isOwnProfile
                    ? 'Add a display name so other members can recognize your posts and Reels.'
                    : "This profile doesn't exist or isn't visible to you.",
                actionLabel: isOwnProfile ? 'Set up profile' : null,
                onAction: isOwnProfile
                    ? () async {
                        await context.push(RoutePaths.communityEditProfile);
                        profileController.load();
                      }
                    : null,
              )
            : RefreshIndicator(
                onRefresh: () async {
                  await profileController.load();
                  await feedController.refresh();
                },
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AscendSpacing.md),
                      child: _ProfileHeader(
                        profile: profileState.profile!,
                        isOwnProfile: isOwnProfile,
                        isMutating: profileState.isMutating,
                        onToggleFollow: profileController.toggleFollow,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AscendSpacing.md,
                      ),
                      child: Text(
                        'Posts',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: AscendSpacing.sm),
                    SizedBox(
                      height: 480,
                      child: CommunityPostListView(
                        state: feedState,
                        onRefresh: feedController.refresh,
                        onLoadMore: feedController.loadMore,
                        onLike: (post) => feedController.toggleLike(post.id),
                        onSave: (post) => feedController.toggleSave(post.id),
                        onDelete: isOwnProfile
                            ? (post) => feedController.removePost(post.id)
                            : null,
                        onTapPost: (post) => context.push(
                          post.mediaType == CommunityPostMediaType.video
                              ? RoutePaths.reelsViewerPath(post.id)
                              : RoutePaths.communityPostDetailPath(post.id),
                        ),
                        onTapAuthor: (_) {},
                        emptyTitle: 'No posts yet',
                        emptyMessage: isOwnProfile
                            ? 'Share your first post from the Community feed.'
                            : "This member hasn't posted anything visible to you yet.",
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final controller = ref.read(
      communityProfileControllerProvider(userId).notifier,
    );
    final messenger = ScaffoldMessenger.of(context);
    if (action == 'block') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Block this member?'),
          content: const Text(
            "You won't see their posts or profile, and they won't see yours. This also removes "
            'any follow between you.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Block'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      final ok = await controller.block();
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(ok ? 'Member blocked.' : "Couldn't block — try again."),
        ),
      );
      if (ok) context.pop();
      return;
    }
    if (action == 'report') {
      final reason = await showDialog<String>(
        context: context,
        builder: (context) {
          final reasonController = TextEditingController();
          return AlertDialog(
            title: const Text('Report this profile'),
            content: TextField(
              controller: reasonController,
              decoration: const InputDecoration(hintText: 'What happened?'),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, reasonController.text),
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );
      if (reason == null || reason.trim().isEmpty) return;
      final ok = await controller.report(reason.trim());
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Report submitted — a moderator will review it.'
                : "Couldn't submit — try again.",
          ),
        ),
      );
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.isOwnProfile,
    required this.isMutating,
    required this.onToggleFollow,
  });

  final CommunityProfile profile;
  final bool isOwnProfile;
  final bool isMutating;
  final VoidCallback onToggleFollow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AscendCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: profile.avatarUrl != null
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null
                    ? const Icon(Icons.person_outline, size: 28)
                    : null,
              ),
              const SizedBox(width: AscendSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.displayName,
                            style: theme.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (profile.isTrainer) ...[
                          const SizedBox(width: AscendSpacing.xs),
                          Icon(
                            Icons.verified_outlined,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    if (profile.bio != null)
                      Text(profile.bio!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AscendSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CountColumn(label: 'Posts', value: profile.postCount ?? 0),
              _CountColumn(
                label: 'Followers',
                value: profile.followerCount ?? 0,
              ),
              _CountColumn(
                label: 'Following',
                value: profile.followingCount ?? 0,
              ),
            ],
          ),
          if (!isOwnProfile) ...[
            const SizedBox(height: AscendSpacing.md),
            SizedBox(
              width: double.infinity,
              child: (profile.isFollowedByViewer ?? false)
                  ? AscendSecondaryButton(
                      label: 'Following',
                      isLoading: isMutating,
                      onPressed: isMutating ? null : onToggleFollow,
                    )
                  : AscendPrimaryButton(
                      label: 'Follow',
                      isLoading: isMutating,
                      onPressed: isMutating ? null : onToggleFollow,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountColumn extends StatelessWidget {
  const _CountColumn({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text('$value', style: theme.textTheme.titleMedium),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
