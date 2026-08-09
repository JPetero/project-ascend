import 'community_post.dart';

/// A creator's own content performance (Build Session 10 Part 23) — real,
/// already-persisted like/comment/save counts aggregated across every
/// post they've ever made. There is no view/impression/reach tracking
/// for organic posts anywhere in the backend, so none is fabricated
/// here; see services/api/src/modules/community/community.service.ts's
/// `getMyContentAnalytics` doc comment for why Ascend Promote's paid
/// campaign metrics are a deliberately separate, per-campaign number.
class ContentAnalytics {
  const ContentAnalytics({
    required this.totalPosts,
    required this.totalLikes,
    required this.totalComments,
    required this.totalSaves,
    required this.posts,
  });

  final int totalPosts;
  final int totalLikes;
  final int totalComments;
  final int totalSaves;
  final List<PostEngagement> posts;

  factory ContentAnalytics.fromJson(Map<String, dynamic> json) {
    final posts = json['posts'] as List<dynamic>;
    return ContentAnalytics(
      totalPosts: json['totalPosts'] as int,
      totalLikes: json['totalLikes'] as int,
      totalComments: json['totalComments'] as int,
      totalSaves: json['totalSaves'] as int,
      posts: posts
          .map((p) => PostEngagement.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// One post's engagement, already sorted server-side by
/// [engagementTotal] descending (most-engaged content first).
class PostEngagement {
  const PostEngagement({
    required this.id,
    required this.mediaType,
    required this.caption,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.saveCount,
    required this.engagementTotal,
  });

  final String id;
  final CommunityPostMediaType mediaType;
  final String? caption;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final int saveCount;
  final int engagementTotal;

  factory PostEngagement.fromJson(Map<String, dynamic> json) {
    return PostEngagement(
      id: json['id'] as String,
      mediaType: communityPostMediaTypeFromJson(json['mediaType'] as String),
      caption: json['caption'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      likeCount: json['likeCount'] as int,
      commentCount: json['commentCount'] as int,
      saveCount: json['saveCount'] as int,
      engagementTotal: json['engagementTotal'] as int,
    );
  }
}
