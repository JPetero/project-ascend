import 'package:mobile/features/community/data/community_repository.dart';
import 'package:mobile/features/community/domain/community_post.dart';
import 'package:mobile/features/community/domain/community_profile.dart';

CommunityPost samplePost({
  String id = 'post-1',
  String authorId = 'author-1',
  CommunityProfile? author,
  CommunityPostMediaType mediaType = CommunityPostMediaType.text,
  String? caption = 'Hello Community',
  CommunityVisibility visibility = CommunityVisibility.public,
  int likeCount = 0,
  int commentCount = 0,
  int saveCount = 0,
  bool isLikedByViewer = false,
  bool isSavedByViewer = false,
  bool isOwnPost = false,
}) {
  return CommunityPost(
    id: id,
    authorId: authorId,
    author: author ?? CommunityProfile(userId: authorId, displayName: 'Ada'),
    mediaType: mediaType,
    caption: caption,
    visibility: visibility,
    isApproved: true,
    isTrainerContent: false,
    likeCount: likeCount,
    commentCount: commentCount,
    saveCount: saveCount,
    isLikedByViewer: isLikedByViewer,
    isSavedByViewer: isSavedByViewer,
    isOwnPost: isOwnPost,
    createdAt: DateTime.utc(2026, 8, 6),
  );
}

/// In-memory stand-in for [CommunityRepository] — tests seed [posts] and
/// [profiles] directly instead of hitting a real backend.
class FakeCommunityRepository implements CommunityRepository {
  FakeCommunityRepository({
    List<CommunityPost>? posts,
    List<CommunityProfile>? profiles,
  }) : posts = posts ?? [],
       profiles = profiles ?? [];

  final List<CommunityPost> posts;
  final List<CommunityProfile> profiles;
  final Set<String> savedPostIds = {};
  final Set<String> followedUserIds = {};
  final List<({String targetType, String targetId, String reason})>
  reportsFiled = [];
  bool throwOnNextCall = false;

  void _maybeThrow() {
    if (throwOnNextCall) {
      throwOnNextCall = false;
      throw Exception('simulated failure');
    }
  }

  @override
  Future<CommunityProfile> upsertOwnProfile({
    required String displayName,
    String? bio,
    String? avatarUrl,
    bool? isTrainer,
  }) async {
    final profile = CommunityProfile(
      userId: 'me',
      displayName: displayName,
      bio: bio,
      avatarUrl: avatarUrl,
      isTrainer: isTrainer ?? false,
    );
    profiles.removeWhere((p) => p.userId == 'me');
    profiles.add(profile);
    return profile;
  }

  @override
  Future<CommunityProfile> getProfile(String userId) async {
    return profiles.firstWhere(
      (p) => p.userId == userId,
      orElse: () => throw Exception('not found'),
    );
  }

  @override
  Future<CommunityPost> createPost({
    CommunityPostMediaType mediaType = CommunityPostMediaType.text,
    String? mediaUrl,
    String? caption,
    CommunityVisibility visibility = CommunityVisibility.public,
    bool isTrainerContent = false,
  }) async {
    final post = samplePost(
      id: 'post-${posts.length}',
      caption: caption,
      mediaType: mediaType,
      visibility: visibility,
      isOwnPost: true,
    );
    posts.insert(0, post);
    return post;
  }

  @override
  Future<List<CommunityPost>> listFeed({
    int page = 1,
    int limit = 20,
    String? authorId,
  }) async {
    _maybeThrow();
    final filtered = authorId == null
        ? posts
        : posts.where((p) => p.authorId == authorId).toList();
    final start = (page - 1) * limit;
    if (start >= filtered.length) return [];
    return filtered.skip(start).take(limit).toList();
  }

  @override
  Future<List<CommunityPost>> listSaved({int page = 1, int limit = 20}) async {
    return posts.where((p) => savedPostIds.contains(p.id)).toList();
  }

  @override
  Future<CommunityPost> getPost(String id) async {
    return posts.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('not found'),
    );
  }

  @override
  Future<void> deletePost(String id) async {
    _maybeThrow();
    posts.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> like(String postId) async {
    _replace(
      postId,
      (p) => p.copyWith(isLikedByViewer: true, likeCount: p.likeCount + 1),
    );
  }

  @override
  Future<void> unlike(String postId) async {
    _replace(
      postId,
      (p) => p.copyWith(isLikedByViewer: false, likeCount: p.likeCount - 1),
    );
  }

  @override
  Future<void> save(String postId) async {
    savedPostIds.add(postId);
    _replace(
      postId,
      (p) => p.copyWith(isSavedByViewer: true, saveCount: p.saveCount + 1),
    );
  }

  @override
  Future<void> unsave(String postId) async {
    savedPostIds.remove(postId);
    _replace(
      postId,
      (p) => p.copyWith(isSavedByViewer: false, saveCount: p.saveCount - 1),
    );
  }

  @override
  Future<CommunityComment> addComment(String postId, String body) async {
    _replace(postId, (p) => p.copyWith(commentCount: p.commentCount + 1));
    return CommunityComment(
      id: 'comment-${DateTime.now().microsecondsSinceEpoch}',
      postId: postId,
      authorId: 'me',
      body: body,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<CommunityComment>> listComments(
    String postId, {
    int page = 1,
    int limit = 50,
  }) async {
    return [];
  }

  @override
  Future<void> deleteComment(String id) async {}

  @override
  Future<void> follow(String userId) async {
    followedUserIds.add(userId);
  }

  @override
  Future<void> unfollow(String userId) async {
    followedUserIds.remove(userId);
  }

  @override
  Future<List<CommunityProfile>> listFollowers(
    String userId, {
    int page = 1,
    int limit = 50,
  }) async {
    return [];
  }

  @override
  Future<List<CommunityProfile>> listFollowing(
    String userId, {
    int page = 1,
    int limit = 50,
  }) async {
    return [];
  }

  @override
  Future<void> block(String userId) async {}

  @override
  Future<void> unblock(String userId) async {}

  @override
  Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    reportsFiled.add((
      targetType: targetType,
      targetId: targetId,
      reason: reason,
    ));
  }

  void _replace(String postId, CommunityPost Function(CommunityPost) update) {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index != -1) posts[index] = update(posts[index]);
  }
}
