import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../sharing/presentation/screens/share_content_screen.dart';
import '../../domain/community_post.dart';
import '../providers/community_feed_controller.dart';
import 'community_post_card.dart';

/// The shared scrollable post list — loading/error/empty states, pull to
/// refresh, and infinite scroll — used by both the main feed and the
/// Saved posts screen so they stay visually identical.
class CommunityPostListView extends StatefulWidget {
  const CommunityPostListView({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onLike,
    required this.onSave,
    required this.onTapPost,
    required this.onTapAuthor,
    this.onDelete,
    this.onReport,
    this.emptyTitle = 'No posts yet',
    this.emptyMessage =
        'Follow other members or share your own workout, progress, or a quick Reel to get started.',
  });

  final CommunityFeedState state;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final void Function(CommunityPost post) onLike;
  final void Function(CommunityPost post) onSave;
  final void Function(CommunityPost post) onTapPost;
  final void Function(CommunityPost post) onTapAuthor;
  final void Function(CommunityPost post)? onDelete;
  final Future<void> Function(CommunityPost post, String reason)? onReport;
  final String emptyTitle;
  final String emptyMessage;

  @override
  State<CommunityPostListView> createState() => _CommunityPostListViewState();
}

class _CommunityPostListViewState extends State<CommunityPostListView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_maybeLoadMore);
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (state.isLoading && state.posts.isEmpty) {
      return const AscendLoadingIndicator(label: 'Loading posts');
    }
    if (state.error != null && state.posts.isEmpty) {
      return AscendEmptyState(
        icon: Icons.error_outline,
        title: "Couldn't load posts",
        message: state.error!,
        actionLabel: 'Try again',
        onAction: () => widget.onRefresh(),
      );
    }
    if (state.posts.isEmpty) {
      return AscendEmptyState(
        icon: Icons.groups_outlined,
        title: widget.emptyTitle,
        message: widget.emptyMessage,
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AscendSpacing.md),
        itemCount: state.posts.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AscendSpacing.md),
        itemBuilder: (context, index) {
          if (index >= state.posts.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AscendSpacing.md),
              child: AscendLoadingIndicator(),
            );
          }
          final post = state.posts[index];
          return CommunityPostCard(
            post: post,
            onTap: () => widget.onTapPost(post),
            onAuthorTap: () => widget.onTapAuthor(post),
            onLike: () => widget.onLike(post),
            onSave: () => widget.onSave(post),
            onDelete: widget.onDelete != null && post.isOwnPost
                ? () => widget.onDelete!(post)
                : null,
            onReport: widget.onReport != null && !post.isOwnPost
                ? (reason) => widget.onReport!(post, reason)
                : null,
            onShare: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => ShareContentScreen(
                  content: communityPostShareContent(post),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
