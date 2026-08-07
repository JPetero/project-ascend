import 'community_profile.dart';

enum CommunityPostMediaType { text, image, video }

CommunityPostMediaType communityPostMediaTypeFromJson(String value) =>
    CommunityPostMediaType.values.firstWhere(
      (t) => t.name.toUpperCase() == value,
      orElse: () => CommunityPostMediaType.text,
    );

String communityPostMediaTypeToJson(CommunityPostMediaType type) =>
    type.name.toUpperCase();

enum CommunityVisibility { public, followers, private }

CommunityVisibility communityVisibilityFromJson(String value) =>
    CommunityVisibility.values.firstWhere(
      (v) => v.name.toUpperCase() == value,
      orElse: () => CommunityVisibility.public,
    );

String communityVisibilityToJson(CommunityVisibility visibility) =>
    visibility.name.toUpperCase();

String communityVisibilityLabel(CommunityVisibility visibility) =>
    switch (visibility) {
      CommunityVisibility.public => 'Public',
      CommunityVisibility.followers => 'Followers only',
      CommunityVisibility.private => 'Only me',
    };

/// A community post — a VIDEO post with a caption is what the product
/// spec calls a "Reel"; there is no separate reel type, see
/// services/api/prisma/schema.prisma's CommunityPostMediaType comment.
class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorId,
    this.author,
    required this.mediaType,
    this.mediaUrl,
    this.caption,
    required this.visibility,
    required this.isApproved,
    required this.isTrainerContent,
    required this.likeCount,
    required this.commentCount,
    required this.saveCount,
    required this.isLikedByViewer,
    required this.isSavedByViewer,
    required this.isOwnPost,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final CommunityProfile? author;
  final CommunityPostMediaType mediaType;
  final String? mediaUrl;
  final String? caption;
  final CommunityVisibility visibility;
  final bool isApproved;
  final bool isTrainerContent;
  final int likeCount;
  final int commentCount;
  final int saveCount;
  final bool isLikedByViewer;
  final bool isSavedByViewer;
  final bool isOwnPost;
  final DateTime createdAt;

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'] as Map<String, dynamic>?;
    return CommunityPost(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      author: authorJson != null ? CommunityProfile.fromJson(authorJson) : null,
      mediaType: communityPostMediaTypeFromJson(json['mediaType'] as String),
      mediaUrl: json['mediaUrl'] as String?,
      caption: json['caption'] as String?,
      visibility: communityVisibilityFromJson(json['visibility'] as String),
      isApproved: (json['moderationStatus'] as String?) == 'APPROVED',
      isTrainerContent: json['isTrainerContent'] as bool? ?? false,
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      saveCount: json['saveCount'] as int? ?? 0,
      isLikedByViewer: json['isLikedByViewer'] as bool? ?? false,
      isSavedByViewer: json['isSavedByViewer'] as bool? ?? false,
      isOwnPost: json['isOwnPost'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  CommunityPost copyWith({
    int? likeCount,
    int? commentCount,
    int? saveCount,
    bool? isLikedByViewer,
    bool? isSavedByViewer,
  }) {
    return CommunityPost(
      id: id,
      authorId: authorId,
      author: author,
      mediaType: mediaType,
      mediaUrl: mediaUrl,
      caption: caption,
      visibility: visibility,
      isApproved: isApproved,
      isTrainerContent: isTrainerContent,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      saveCount: saveCount ?? this.saveCount,
      isLikedByViewer: isLikedByViewer ?? this.isLikedByViewer,
      isSavedByViewer: isSavedByViewer ?? this.isSavedByViewer,
      isOwnPost: isOwnPost,
      createdAt: createdAt,
    );
  }
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.postId,
    required this.authorId,
    this.author,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String authorId;
  final CommunityProfile? author;
  final String body;
  final DateTime createdAt;

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'] as Map<String, dynamic>?;
    return CommunityComment(
      id: json['id'] as String,
      postId: json['postId'] as String,
      authorId: json['authorId'] as String,
      author: authorJson != null ? CommunityProfile.fromJson(authorJson) : null,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
