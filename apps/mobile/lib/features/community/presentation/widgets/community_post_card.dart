import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/community_post.dart';

/// One feed/profile post card — shared by the feed and profile screens
/// so a Reel (VIDEO + caption) and a plain text post render identically
/// apart from the media placeholder. There is no video player here (see
/// packages/docs/build-session-7.md Part 4's platform-limitations
/// section) — a VIDEO post shows a labeled placeholder, never a fake
/// thumbnail or an implied working player.
class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onAuthorTap,
    required this.onLike,
    required this.onSave,
    this.onDelete,
  });

  final CommunityPost post;
  final VoidCallback onTap;
  final VoidCallback onAuthorTap;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final author = post.author;

    return AscendCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onAuthorTap,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: author?.avatarUrl != null
                          ? NetworkImage(author!.avatarUrl!)
                          : null,
                      child: author?.avatarUrl == null
                          ? const Icon(Icons.person_outline, size: 18)
                          : null,
                    ),
                    const SizedBox(width: AscendSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              author?.displayName ?? 'Ascend member',
                              style: theme.textTheme.titleSmall,
                            ),
                            if (author?.isTrainer ?? false) ...[
                              const SizedBox(width: AscendSpacing.xs),
                              Icon(
                                Icons.verified_outlined,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                        if (post.mediaType == CommunityPostMediaType.video)
                          Text('Reel', style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Delete post',
                  onPressed: onDelete,
                ),
            ],
          ),
          if (post.mediaType != CommunityPostMediaType.text) ...[
            const SizedBox(height: AscendSpacing.sm),
            _MediaPlaceholder(mediaType: post.mediaType),
          ],
          if (post.caption != null && post.caption!.isNotEmpty) ...[
            const SizedBox(height: AscendSpacing.sm),
            Text(post.caption!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: AscendSpacing.sm),
          Row(
            children: [
              _ActionButton(
                icon: post.isLikedByViewer
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: post.isLikedByViewer ? theme.colorScheme.error : null,
                label: '${post.likeCount}',
                onPressed: onLike,
              ),
              const SizedBox(width: AscendSpacing.md),
              _ActionButton(
                icon: Icons.mode_comment_outlined,
                label: '${post.commentCount}',
                onPressed: onTap,
              ),
              const Spacer(),
              _ActionButton(
                icon: post.isSavedByViewer
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                label: null,
                onPressed: onSave,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.mediaType});

  final CommunityPostMediaType mediaType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AscendRadius.small),
        ),
        child: Center(
          child: Icon(
            mediaType == CommunityPostMediaType.video
                ? Icons.play_circle_outline
                : Icons.image_outlined,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String? label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AscendRadius.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AscendSpacing.xs,
          horizontal: AscendSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(label!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
