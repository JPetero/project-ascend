import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/community_repository.dart';
import '../../domain/community_post.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(apiClient: ref.watch(apiClientProvider));
});

class CommunityFeedState {
  const CommunityFeedState({
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<CommunityPost> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  CommunityFeedState copyWith({
    List<CommunityPost>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return CommunityFeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Drives one feed: the general feed (own + public + followed-followers
/// posts) when [authorId] is null, or a single author's posts (still
/// visibility-filtered server-side) when it's set — see
/// `CommunityService.buildVisibleWhere` on the backend. Likes/saves are
/// applied optimistically and rolled back on failure so tapping feels
/// instant without ever showing a count that doesn't match the server.
class CommunityFeedController extends StateNotifier<CommunityFeedState> {
  CommunityFeedController({
    required CommunityRepository repository,
    this.authorId,
    this.savedOnly = false,
  }) : _repository = repository,
       super(const CommunityFeedState()) {
    refresh();
  }

  final CommunityRepository _repository;
  final String? authorId;
  final bool savedOnly;
  static const _limit = 20;
  int _page = 1;
  bool followingOnly = false;

  Future<List<CommunityPost>> _fetch(int page) {
    return savedOnly
        ? _repository.listSaved(page: page, limit: _limit)
        : _repository.listFeed(
            page: page,
            limit: _limit,
            authorId: authorId,
            followingOnly: followingOnly,
          );
  }

  /// Switches between "Discover" (own + any PUBLIC + followed
  /// FOLLOWERS-only posts) and "Following" (own + followed-author posts
  /// only) — Build Session 8 Part 4.
  Future<void> setFollowingOnly(bool value) async {
    if (followingOnly == value) return;
    followingOnly = value;
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final posts = await _fetch(1);
      _page = 1;
      state = CommunityFeedState(posts: posts, hasMore: posts.length == _limit);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final next = _page + 1;
      final posts = await _fetch(next);
      _page = next;
      state = state.copyWith(
        posts: [...state.posts, ...posts],
        isLoadingMore: false,
        hasMore: posts.length == _limit,
      );
    } catch (error) {
      state = state.copyWith(isLoadingMore: false, error: error.toString());
    }
  }

  Future<void> toggleLike(String postId) async {
    final post = _findPost(postId);
    if (post == null) return;
    final wasLiked = post.isLikedByViewer;
    _replace(
      post.copyWith(
        isLikedByViewer: !wasLiked,
        likeCount: post.likeCount + (wasLiked ? -1 : 1),
      ),
    );
    try {
      wasLiked
          ? await _repository.unlike(postId)
          : await _repository.like(postId);
    } catch (_) {
      _replace(post);
    }
  }

  Future<void> toggleSave(String postId) async {
    final post = _findPost(postId);
    if (post == null) return;
    final wasSaved = post.isSavedByViewer;
    if (savedOnly && wasSaved) {
      // Unsaving from the "Saved" list removes it from view entirely
      // rather than leaving a now-unsaved post in a saved-only list.
      state = state.copyWith(
        posts: state.posts.where((p) => p.id != postId).toList(),
      );
      try {
        await _repository.unsave(postId);
      } catch (_) {
        state = state.copyWith(posts: [post, ...state.posts]);
      }
      return;
    }
    _replace(
      post.copyWith(
        isSavedByViewer: !wasSaved,
        saveCount: post.saveCount + (wasSaved ? -1 : 1),
      ),
    );
    try {
      wasSaved
          ? await _repository.unsave(postId)
          : await _repository.save(postId);
    } catch (_) {
      _replace(post);
    }
  }

  Future<void> removePost(String postId) async {
    final previous = state.posts;
    state = state.copyWith(
      posts: previous.where((p) => p.id != postId).toList(),
    );
    try {
      await _repository.deletePost(postId);
    } catch (error) {
      state = state.copyWith(posts: previous, error: error.toString());
    }
  }

  Future<void> reportPost(String postId, String reason) async {
    await _repository.report(
      targetType: 'POST',
      targetId: postId,
      reason: reason,
    );
  }

  void _replace(CommunityPost updated) {
    state = state.copyWith(
      posts: [
        for (final p in state.posts)
          if (p.id == updated.id) updated else p,
      ],
    );
  }

  CommunityPost? _findPost(String postId) {
    for (final post in state.posts) {
      if (post.id == postId) return post;
    }
    return null;
  }
}

final communityFeedControllerProvider =
    StateNotifierProvider.family<
      CommunityFeedController,
      CommunityFeedState,
      String?
    >((ref, authorId) {
      return CommunityFeedController(
        repository: ref.watch(communityRepositoryProvider),
        authorId: authorId,
      );
    });

final communitySavedFeedControllerProvider =
    StateNotifierProvider<CommunityFeedController, CommunityFeedState>((ref) {
      return CommunityFeedController(
        repository: ref.watch(communityRepositoryProvider),
        savedOnly: true,
      );
    });
