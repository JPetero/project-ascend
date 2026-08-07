import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/community_post.dart';
import '../providers/post_detail_controller.dart';
import '../widgets/community_post_card.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final controller = ref.read(
      postDetailControllerProvider(widget.postId).notifier,
    );
    final body = _commentController.text;
    _commentController.clear();
    final posted = await controller.addComment(body);
    if (!posted) _commentController.text = body;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postDetailControllerProvider(widget.postId));
    final controller = ref.read(
      postDetailControllerProvider(widget.postId).notifier,
    );
    final viewerId = ref.watch(
      authControllerProvider.select((s) => s.user?.id),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: SafeArea(
        child: state.isLoading
            ? const AscendLoadingIndicator()
            : state.post == null
            ? AscendEmptyState(
                icon: Icons.error_outline,
                title: "Couldn't load this post",
                message:
                    state.error ??
                    'It may have been deleted or is no longer visible to you.',
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(AscendSpacing.md),
                      children: [
                        CommunityPostCard(
                          post: state.post!,
                          onTap: () {},
                          onAuthorTap: () => context.push(
                            RoutePaths.communityProfilePath(
                              state.post!.authorId,
                            ),
                          ),
                          onLike: controller.toggleLike,
                          onSave: controller.toggleSave,
                        ),
                        const SizedBox(height: AscendSpacing.lg),
                        Text(
                          'Comments',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AscendSpacing.sm),
                        if (state.comments.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AscendSpacing.md,
                            ),
                            child: Text(
                              'No comments yet — be the first to say something.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )
                        else
                          for (final comment in state.comments)
                            _CommentTile(
                              comment: comment,
                              canDelete:
                                  comment.authorId == viewerId ||
                                  state.post!.authorId == viewerId,
                              onDelete: () =>
                                  controller.deleteComment(comment.id),
                            ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(AscendSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              hintText: 'Add a comment…',
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _submitComment(),
                          ),
                        ),
                        IconButton(
                          icon: state.isPostingComment
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                          onPressed: state.isPostingComment
                              ? null
                              : _submitComment,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.canDelete,
    required this.onDelete,
  });

  final CommunityComment comment;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AscendSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: comment.author?.avatarUrl != null
                ? NetworkImage(comment.author!.avatarUrl!)
                : null,
            child: comment.author?.avatarUrl == null
                ? const Icon(Icons.person_outline, size: 16)
                : null,
          ),
          const SizedBox(width: AscendSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.author?.displayName ?? 'Ascend member',
                  style: theme.textTheme.labelMedium,
                ),
                Text(comment.body, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              tooltip: 'Delete comment',
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
