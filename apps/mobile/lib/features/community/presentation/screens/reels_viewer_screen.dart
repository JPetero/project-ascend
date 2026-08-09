import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/media/presentation/widgets/ascend_video_player.dart';
import '../../../sharing/presentation/screens/share_content_screen.dart';
import '../../domain/community_post.dart';
import '../providers/community_feed_controller.dart';
import '../widgets/community_post_card.dart';
import 'post_detail_screen.dart';

/// A dedicated full-screen vertical-swipe Reel viewer (Build Session 10
/// Part 22) — previously Reels only ever played inline in the ordinary
/// feed list; see packages/docs/product/parking-lot.md's "still open"
/// entry for this exact gap. Drives the same
/// `CommunityFeedController`/like/save/report machinery as the regular
/// feed (via `reelsOnly: true`), just presented one video at a time.
///
/// [initialPostId] positions the viewer on that post if it's present in
/// the loaded Reels feed (e.g. tapped from the regular feed); otherwise
/// it opens at the top of the feed.
class ReelsViewerScreen extends ConsumerStatefulWidget {
  const ReelsViewerScreen({super.key, this.initialPostId});

  final String? initialPostId;

  @override
  ConsumerState<ReelsViewerScreen> createState() => _ReelsViewerScreenState();
}

class _ReelsViewerScreenState extends ConsumerState<ReelsViewerScreen> {
  final _pageController = PageController();
  int _currentIndex = 0;
  bool _hasPositionedInitialPage = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _positionInitialPageIfNeeded(List<CommunityPost> posts) {
    if (_hasPositionedInitialPage || widget.initialPostId == null) return;
    // The feed's first build is synchronously `posts: []` while the fetch
    // is in flight — wait for it to actually resolve before deciding
    // whether the target post is missing vs. just not loaded yet.
    if (posts.isEmpty) return;
    final index = posts.indexWhere((p) => p.id == widget.initialPostId);
    _hasPositionedInitialPage = true;
    if (index <= 0) return;
    _currentIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityReelsFeedControllerProvider);
    final controller = ref.read(communityReelsFeedControllerProvider.notifier);
    _positionInitialPageIfNeeded(state.posts);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : state.posts.isEmpty
            ? AscendEmptyState(
                icon: Icons.video_camera_back_outlined,
                title: 'No Reels yet',
                message:
                    state.error ??
                    'Once someone posts a Reel, it shows up here.',
              )
            : Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: state.posts.length + (state.hasMore ? 1 : 0),
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                      if (index >= state.posts.length - 3) {
                        controller.loadMore();
                      }
                    },
                    itemBuilder: (context, index) {
                      if (index >= state.posts.length) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                      final post = state.posts[index];
                      return _ReelPage(
                        key: ValueKey(post.id),
                        post: post,
                        isCurrent: index == _currentIndex,
                        onLike: () => controller.toggleLike(post.id),
                        onSave: () => controller.toggleSave(post.id),
                      );
                    },
                  ),
                  Positioned(
                    top: AscendSpacing.sm,
                    left: AscendSpacing.sm,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ReelPage extends StatelessWidget {
  const _ReelPage({
    super.key,
    required this.post,
    required this.isCurrent,
    required this.onLike,
    required this.onSave,
  });

  final CommunityPost post;
  final bool isCurrent;
  final VoidCallback onLike;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final mediaUrl = post.mediaUrl;
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: mediaUrl == null
              ? const Icon(
                  Icons.videocam_off_outlined,
                  color: Colors.white54,
                  size: 48,
                )
              : AscendVideoPlayer(url: mediaUrl, autoplay: isCurrent),
        ),
        Positioned(
          left: AscendSpacing.md,
          right: 72,
          bottom: AscendSpacing.lg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                post.author?.displayName ?? 'Ascend member',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (post.caption != null) ...[
                const SizedBox(height: AscendSpacing.xs),
                Text(
                  post.caption!,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          right: AscendSpacing.sm,
          bottom: AscendSpacing.lg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ReelActionButton(
                icon: post.isLikedByViewer
                    ? Icons.favorite
                    : Icons.favorite_border,
                iconColor: post.isLikedByViewer
                    ? Theme.of(context).colorScheme.error
                    : Colors.white,
                label: '${post.likeCount}',
                onPressed: onLike,
              ),
              const SizedBox(height: AscendSpacing.md),
              _ReelActionButton(
                icon: Icons.mode_comment_outlined,
                label: '${post.commentCount}',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => PostDetailScreen(postId: post.id),
                  ),
                ),
              ),
              const SizedBox(height: AscendSpacing.md),
              _ReelActionButton(
                icon: post.isSavedByViewer
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                label: '${post.saveCount}',
                onPressed: onSave,
              ),
              const SizedBox(height: AscendSpacing.md),
              _ReelActionButton(
                icon: Icons.ios_share_outlined,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => ShareContentScreen(
                      content: communityPostShareContent(post),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReelActionButton extends StatelessWidget {
  const _ReelActionButton({
    required this.icon,
    this.label,
    this.iconColor = Colors.white,
    required this.onPressed,
  });

  final IconData icon;
  final String? label;
  final Color iconColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: iconColor, size: 30),
          onPressed: onPressed,
        ),
        if (label != null)
          Text(
            label!,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
      ],
    );
  }
}
