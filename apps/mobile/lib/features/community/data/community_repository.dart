import '../../../core/networking/api_client.dart';
import '../domain/community_post.dart';
import '../domain/community_profile.dart';

/// Community profiles/posts/Reels/likes/comments/saves/follows/blocks/
/// reports — thin client for services/api/src/modules/community. Every
/// list endpoint returns the `{data, meta}`-wrapped-again-by-the-
/// interceptor shape already established for cardio/health-metrics (see
/// ResponseEnvelopeInterceptor's doc comment): `envelope.data!['data']`.
class CommunityRepository {
  CommunityRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  // --- Profile ------------------------------------------------------------

  Future<CommunityProfile> upsertOwnProfile({
    required String displayName,
    String? bio,
    String? avatarUrl,
    bool? isTrainer,
  }) async {
    final envelope = await _apiClient.post(
      '/community/profile',
      (data) => data as Map<String, dynamic>,
      data: {
        'displayName': displayName,
        'bio': ?bio,
        'avatarUrl': ?avatarUrl,
        'isTrainer': ?isTrainer,
      },
    );
    return CommunityProfile.fromJson(envelope.data!);
  }

  Future<CommunityProfile> getProfile(String userId) async {
    final envelope = await _apiClient.get(
      '/community/profile/$userId',
      (data) => data as Map<String, dynamic>,
    );
    return CommunityProfile.fromJson(envelope.data!);
  }

  // --- Posts ----------------------------------------------------------

  Future<CommunityPost> createPost({
    CommunityPostMediaType mediaType = CommunityPostMediaType.text,
    String? mediaUrl,
    String? caption,
    CommunityVisibility visibility = CommunityVisibility.public,
    bool isTrainerContent = false,
  }) async {
    final envelope = await _apiClient.post(
      '/community/posts',
      (data) => data as Map<String, dynamic>,
      data: {
        'mediaType': communityPostMediaTypeToJson(mediaType),
        'mediaUrl': ?mediaUrl,
        'caption': ?caption,
        'visibility': communityVisibilityToJson(visibility),
        'isTrainerContent': isTrainerContent,
      },
    );
    return CommunityPost.fromJson(envelope.data!);
  }

  Future<List<CommunityPost>> listFeed({
    int page = 1,
    int limit = 20,
    String? authorId,
  }) async {
    final envelope = await _apiClient.get(
      '/community/posts',
      (data) => data as Map<String, dynamic>,
      query: {'page': page, 'limit': limit, 'authorId': ?authorId},
    );
    final items = envelope.data!['data'] as List<dynamic>;
    return items
        .map((p) => CommunityPost.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<List<CommunityPost>> listSaved({int page = 1, int limit = 20}) async {
    final envelope = await _apiClient.get(
      '/community/posts/saved',
      (data) => data as Map<String, dynamic>,
      query: {'page': page, 'limit': limit},
    );
    final items = envelope.data!['data'] as List<dynamic>;
    return items
        .map((p) => CommunityPost.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<CommunityPost> getPost(String id) async {
    final envelope = await _apiClient.get(
      '/community/posts/$id',
      (data) => data as Map<String, dynamic>,
    );
    return CommunityPost.fromJson(envelope.data!);
  }

  Future<void> deletePost(String id) async {
    await _apiClient.delete('/community/posts/$id', (_) => null);
  }

  // --- Likes ------------------------------------------------------------

  Future<void> like(String postId) async {
    await _apiClient.post('/community/posts/$postId/like', (_) => null);
  }

  Future<void> unlike(String postId) async {
    await _apiClient.delete('/community/posts/$postId/like', (_) => null);
  }

  // --- Saves ------------------------------------------------------------

  Future<void> save(String postId) async {
    await _apiClient.post('/community/posts/$postId/save', (_) => null);
  }

  Future<void> unsave(String postId) async {
    await _apiClient.delete('/community/posts/$postId/save', (_) => null);
  }

  // --- Comments -----------------------------------------------------------

  Future<CommunityComment> addComment(String postId, String body) async {
    final envelope = await _apiClient.post(
      '/community/posts/$postId/comments',
      (data) => data as Map<String, dynamic>,
      data: {'body': body},
    );
    return CommunityComment.fromJson(envelope.data!);
  }

  Future<List<CommunityComment>> listComments(
    String postId, {
    int page = 1,
    int limit = 50,
  }) async {
    final envelope = await _apiClient.get(
      '/community/posts/$postId/comments',
      (data) => data as Map<String, dynamic>,
      query: {'page': page, 'limit': limit},
    );
    final items = envelope.data!['data'] as List<dynamic>;
    return items
        .map((c) => CommunityComment.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteComment(String id) async {
    await _apiClient.delete('/community/comments/$id', (_) => null);
  }

  // --- Follows --------------------------------------------------------

  Future<void> follow(String userId) async {
    await _apiClient.post('/community/follow/$userId', (_) => null);
  }

  Future<void> unfollow(String userId) async {
    await _apiClient.delete('/community/follow/$userId', (_) => null);
  }

  Future<List<CommunityProfile>> listFollowers(
    String userId, {
    int page = 1,
    int limit = 50,
  }) async {
    final envelope = await _apiClient.get(
      '/community/follow/$userId/followers',
      (data) => data as Map<String, dynamic>,
      query: {'page': page, 'limit': limit},
    );
    final items = envelope.data!['data'] as List<dynamic>;
    return items
        .map((p) => CommunityProfile.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<List<CommunityProfile>> listFollowing(
    String userId, {
    int page = 1,
    int limit = 50,
  }) async {
    final envelope = await _apiClient.get(
      '/community/follow/$userId/following',
      (data) => data as Map<String, dynamic>,
      query: {'page': page, 'limit': limit},
    );
    final items = envelope.data!['data'] as List<dynamic>;
    return items
        .map((p) => CommunityProfile.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  // --- Blocks -------------------------------------------------------------

  Future<void> block(String userId) async {
    await _apiClient.post('/community/block/$userId', (_) => null);
  }

  Future<void> unblock(String userId) async {
    await _apiClient.delete('/community/block/$userId', (_) => null);
  }

  // --- Reports --------------------------------------------------------

  Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    await _apiClient.post(
      '/community/reports',
      (_) => null,
      data: {'targetType': targetType, 'targetId': targetId, 'reason': reason},
    );
  }
}
