import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/community_repository.dart';
import '../../domain/community_post.dart';
import 'community_feed_controller.dart';

class PostDetailState {
  const PostDetailState({
    this.post,
    this.comments = const [],
    this.isLoading = true,
    this.isPostingComment = false,
    this.error,
  });

  final CommunityPost? post;
  final List<CommunityComment> comments;
  final bool isLoading;
  final bool isPostingComment;
  final String? error;

  PostDetailState copyWith({
    CommunityPost? post,
    List<CommunityComment>? comments,
    bool? isLoading,
    bool? isPostingComment,
    String? error,
    bool clearError = false,
  }) {
    return PostDetailState(
      post: post ?? this.post,
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isPostingComment: isPostingComment ?? this.isPostingComment,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// A single post plus its comment thread — kept separate from
/// [CommunityFeedController] since a post detail screen needs comments
/// loaded too, which the feed list never does.
class PostDetailController extends StateNotifier<PostDetailState> {
  PostDetailController({
    required CommunityRepository repository,
    required this.postId,
  }) : _repository = repository,
       super(const PostDetailState()) {
    load();
  }

  final CommunityRepository _repository;
  final String postId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final post = await _repository.getPost(postId);
      final comments = await _repository.listComments(postId);
      state = state.copyWith(post: post, comments: comments, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> toggleLike() async {
    final post = state.post;
    if (post == null) return;
    final wasLiked = post.isLikedByViewer;
    state = state.copyWith(
      post: post.copyWith(
        isLikedByViewer: !wasLiked,
        likeCount: post.likeCount + (wasLiked ? -1 : 1),
      ),
    );
    try {
      wasLiked
          ? await _repository.unlike(postId)
          : await _repository.like(postId);
    } catch (_) {
      state = state.copyWith(post: post);
    }
  }

  Future<void> toggleSave() async {
    final post = state.post;
    if (post == null) return;
    final wasSaved = post.isSavedByViewer;
    state = state.copyWith(
      post: post.copyWith(
        isSavedByViewer: !wasSaved,
        saveCount: post.saveCount + (wasSaved ? -1 : 1),
      ),
    );
    try {
      wasSaved
          ? await _repository.unsave(postId)
          : await _repository.save(postId);
    } catch (_) {
      state = state.copyWith(post: post);
    }
  }

  Future<bool> addComment(String body) async {
    if (body.trim().isEmpty) return false;
    state = state.copyWith(isPostingComment: true, clearError: true);
    try {
      final comment = await _repository.addComment(postId, body.trim());
      final post = state.post;
      state = state.copyWith(
        comments: [...state.comments, comment],
        post: post?.copyWith(commentCount: post.commentCount + 1),
        isPostingComment: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(isPostingComment: false, error: error.toString());
      return false;
    }
  }

  Future<void> deleteComment(String commentId) async {
    final previous = state.comments;
    final post = state.post;
    state = state.copyWith(
      comments: previous.where((c) => c.id != commentId).toList(),
      post: post?.copyWith(commentCount: post.commentCount - 1),
    );
    try {
      await _repository.deleteComment(commentId);
    } catch (error) {
      state = state.copyWith(
        comments: previous,
        post: post,
        error: error.toString(),
      );
    }
  }
}

final postDetailControllerProvider = StateNotifierProvider.family
    .autoDispose<PostDetailController, PostDetailState, String>((ref, postId) {
      return PostDetailController(
        repository: ref.watch(communityRepositoryProvider),
        postId: postId,
      );
    });
