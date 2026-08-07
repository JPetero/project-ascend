import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_shell.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
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
          const ProfileIconAction(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RoutePaths.communityCreatePost),
        tooltip: 'New post',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: CommunityPostListView(
          state: state,
          onRefresh: controller.refresh,
          onLoadMore: controller.loadMore,
          onLike: (post) => controller.toggleLike(post.id),
          onSave: (post) => controller.toggleSave(post.id),
          onDelete: (post) => controller.removePost(post.id),
          onTapPost: (post) =>
              context.push(RoutePaths.communityPostDetailPath(post.id)),
          onTapAuthor: (post) =>
              context.push(RoutePaths.communityProfilePath(post.authorId)),
        ),
      ),
    );
  }
}
