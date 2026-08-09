import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/community_post.dart';
import '../../domain/content_analytics.dart';
import '../providers/content_analytics_controller.dart';

/// A creator's own content performance (Build Session 10 Part 23) —
/// totals plus a per-post breakdown, sorted by engagement, built from
/// real like/comment/save counts already stored for every post. No
/// view/reach numbers are shown because none exist for organic posts;
/// see ContentAnalyticsController's data source doc comment.
class ContentAnalyticsScreen extends ConsumerWidget {
  const ContentAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(contentAnalyticsControllerProvider);
    final controller = ref.read(contentAnalyticsControllerProvider.notifier);

    if (state.isLoading) {
      return const Scaffold(body: SafeArea(child: AscendLoadingIndicator()));
    }

    final analytics = state.analytics;
    if (analytics == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My content')),
        body: SafeArea(
          child: AscendEmptyState(
            icon: Icons.error_outline,
            title: "Couldn't load your content performance",
            message: state.error ?? 'Try again in a moment.',
            actionLabel: 'Try again',
            onAction: controller.load,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My content')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: analytics.totalPosts == 0
              ? ListView(
                  children: const [
                    AscendEmptyState(
                      icon: Icons.insights_outlined,
                      title: 'No content yet',
                      message:
                          'Once you share a post or Reel, its likes, comments, and saves show up here.',
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(AscendSpacing.md),
                  children: [
                    AscendCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _TotalColumn(
                            label: 'Posts',
                            value: analytics.totalPosts,
                          ),
                          _TotalColumn(
                            label: 'Likes',
                            value: analytics.totalLikes,
                          ),
                          _TotalColumn(
                            label: 'Comments',
                            value: analytics.totalComments,
                          ),
                          _TotalColumn(
                            label: 'Saves',
                            value: analytics.totalSaves,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AscendSpacing.lg),
                    Text(
                      'By engagement',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AscendSpacing.sm),
                    for (final post in analytics.posts) ...[
                      _PostEngagementTile(post: post),
                      const SizedBox(height: AscendSpacing.sm),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _TotalColumn extends StatelessWidget {
  const _TotalColumn({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _PostEngagementTile extends StatelessWidget {
  const _PostEngagementTile({required this.post});

  final PostEngagement post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AscendCard(
      child: Row(
        children: [
          Icon(switch (post.mediaType) {
            CommunityPostMediaType.video => Icons.videocam_outlined,
            CommunityPostMediaType.image => Icons.image_outlined,
            CommunityPostMediaType.text => Icons.article_outlined,
          }, color: theme.colorScheme.primary),
          const SizedBox(width: AscendSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.caption?.isNotEmpty == true
                      ? post.caption!
                      : (post.mediaType == CommunityPostMediaType.video
                            ? 'Reel'
                            : 'Untitled post'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AscendSpacing.xs),
                Text(
                  '${_formatDate(post.createdAt)} · ${post.likeCount} likes · '
                  '${post.commentCount} comments · ${post.saveCount} saves',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AscendSpacing.sm),
          Text(
            '${post.engagementTotal}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime date) {
  return '${_months[date.month - 1]} ${date.day}, ${date.year}';
}
