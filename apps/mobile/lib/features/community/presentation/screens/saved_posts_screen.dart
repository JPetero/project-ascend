import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../domain/community_post.dart';
import '../providers/community_feed_controller.dart';
import '../widgets/community_post_list_view.dart';

class SavedPostsScreen extends ConsumerWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communitySavedFeedControllerProvider);
    final controller = ref.read(communitySavedFeedControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved posts')),
      body: SafeArea(
        child: CommunityPostListView(
          state: state,
          onRefresh: controller.refresh,
          onLoadMore: controller.loadMore,
          onLike: (post) => controller.toggleLike(post.id),
          onSave: (post) => controller.toggleSave(post.id),
          onTapPost: (post) => context.push(
            post.mediaType == CommunityPostMediaType.video
                ? RoutePaths.reelsViewerPath(post.id)
                : RoutePaths.communityPostDetailPath(post.id),
          ),
          onTapAuthor: (post) =>
              context.push(RoutePaths.communityProfilePath(post.authorId)),
          emptyTitle: 'Nothing saved yet',
          emptyMessage:
              'Tap the bookmark icon on a post to save it here for later.',
        ),
      ),
    );
  }
}
