import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/media/media_url.dart';
import '../../../../core/media/presentation/widgets/ascend_video_player.dart';
import '../../domain/community_post.dart';

/// One feed/profile post card — shared by the feed and profile screens
/// so a Reel (VIDEO + caption) and a plain text post render identically
/// apart from the media. Build Session 8 Part 4 wires this to real
/// playback: an IMAGE post shows the uploaded photo, a VIDEO post
/// ("Reel") plays through [AscendVideoPlayer]. A post with no mediaUrl
/// (shouldn't happen for a non-TEXT post, but kept honest) falls back
/// to a labeled placeholder rather than a broken image.
class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onAuthorTap,
    required this.onLike,
    required this.onSave,
    this.onDelete,
    this.onReport,
    this.onShare,
  });

  final CommunityPost post;
  final VoidCallback onTap;
  final VoidCallback onAuthorTap;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback? onDelete;
  final Future<void> Function(String reason)? onReport;
  final VoidCallback? onShare;

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
                )
              else if (onReport != null)
                PopupMenuButton<_PostMenuAction>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (action) {
                    switch (action) {
                      case _PostMenuAction.report:
                        _showReportDialog(context, onReport!);
                      case _PostMenuAction.share:
                        onShare?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onShare != null)
                      const PopupMenuItem(
                        value: _PostMenuAction.share,
                        child: Text('Share'),
                      ),
                    const PopupMenuItem(
                      value: _PostMenuAction.report,
                      child: Text('Report'),
                    ),
                  ],
                ),
            ],
          ),
          if (post.mediaType != CommunityPostMediaType.text) ...[
            const SizedBox(height: AscendSpacing.sm),
            _PostMedia(mediaType: post.mediaType, mediaUrl: post.mediaUrl),
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

class _PostMedia extends StatelessWidget {
  const _PostMedia({required this.mediaType, required this.mediaUrl});

  final CommunityPostMediaType mediaType;
  final String? mediaUrl;

  @override
  Widget build(BuildContext context) {
    final url = mediaUrl;
    if (url == null || url.isEmpty) {
      return _MediaPlaceholder(mediaType: mediaType);
    }
    if (mediaType == CommunityPostMediaType.video) {
      return ClipRRect(
        borderRadius: AscendRadius.smallRadius,
        child: AscendVideoPlayer(url: resolveMediaUrl(url)),
      );
    }
    return ClipRRect(
      borderRadius: AscendRadius.smallRadius,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          resolveMediaUrl(url),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _MediaPlaceholder(mediaType: mediaType),
        ),
      ),
    );
  }
}

enum _PostMenuAction { report, share }

Future<void> _showReportDialog(
  BuildContext context,
  Future<void> Function(String reason) onReport,
) async {
  final controller = TextEditingController();
  final reason = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Report this post'),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: const InputDecoration(hintText: 'What\'s wrong with it?'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('Submit'),
        ),
      ],
    ),
  );
  if (reason == null || reason.isEmpty) return;
  await onReport(reason);
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Report submitted.')));
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
