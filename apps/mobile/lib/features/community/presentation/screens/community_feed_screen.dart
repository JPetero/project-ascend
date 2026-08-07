import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/app_shell.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../messages/presentation/providers/conversations_controller.dart';
import '../providers/community_feed_controller.dart';
import '../widgets/community_post_list_view.dart';

/// The Community tab's main feed — own posts, public posts, and
/// followed users' followers-only posts, per Founder Scenario 21 and
/// `CommunityService.buildVisibleWhere` on the backend. Reachable at
/// [RoutePaths.social] (path unchanged from the pre-rename "Social" tab
/// — see route_paths.dart's comment).
class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityFeedControllerProvider(null));
    final controller = ref.read(communityFeedControllerProvider(null).notifier);
    final userId = ref.watch(authControllerProvider.select((s) => s.user?.id));
    final unreadMessages = ref.watch(
      conversationsControllerProvider.select((s) => s.unreadCount),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: unreadMessages > 0,
              label: Text('$unreadMessages'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            tooltip: 'Messages',
            onPressed: () => context.push(RoutePaths.conversations),
          ),
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'Friends',
            onPressed: () => context.push(RoutePaths.friends),
          ),
          IconButton(
            icon: const Icon(Icons.group_work_outlined),
            tooltip: 'Joint Workouts',
            onPressed: () => context.push(RoutePaths.jointWorkouts),
          ),
          IconButton(
            icon: const Icon(Icons.sports_tennis_outlined),
            tooltip: 'Sports',
            onPressed: () => context.push(RoutePaths.sportsMatches),
          ),
          IconButton(
            icon: const Icon(Icons.groups_2_outlined),
            tooltip: 'Trainer Groups',
            onPressed: () => context.push(RoutePaths.trainerGroups),
          ),
          IconButton(
            icon: const Icon(Icons.campaign_outlined),
            tooltip: 'Ascend Promote',
            onPressed: () => context.push(RoutePaths.promoteCampaigns),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            tooltip: 'Saved posts',
            onPressed: () => context.push(RoutePaths.communitySaved),
          ),
          if (userId != null)
            IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              tooltip: 'My Community profile',
              onPressed: () =>
                  context.push(RoutePaths.communityProfilePath(userId)),
            ),
          const NotificationBellAction(),
          const ProfileIconAction(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RoutePaths.communityCreatePost),
        tooltip: 'New post',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AscendSpacing.md,
                AscendSpacing.sm,
                AscendSpacing.md,
                0,
              ),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Discover')),
                  ButtonSegment(value: true, label: Text('Following')),
                ],
                selected: {controller.followingOnly},
                onSelectionChanged: (selected) =>
                    controller.setFollowingOnly(selected.first),
              ),
            ),
            Expanded(
              child: CommunityPostListView(
                state: state,
                onRefresh: controller.refresh,
                onLoadMore: controller.loadMore,
                onLike: (post) => controller.toggleLike(post.id),
                onSave: (post) => controller.toggleSave(post.id),
                onDelete: (post) => controller.removePost(post.id),
                onReport: (post, reason) =>
                    controller.reportPost(post.id, reason),
                onTapPost: (post) =>
                    context.push(RoutePaths.communityPostDetailPath(post.id)),
                onTapAuthor: (post) => context.push(
                  RoutePaths.communityProfilePath(post.authorId),
                ),
                emptyTitle: controller.followingOnly
                    ? 'Nobody you follow has posted yet'
                    : 'No posts yet',
                emptyMessage: controller.followingOnly
                    ? 'Follow more members to see their posts here, or switch to Discover.'
                    : 'Follow other members or share your own workout, progress, or a quick Reel to get started.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
