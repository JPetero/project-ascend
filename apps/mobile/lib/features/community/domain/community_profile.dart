/// Public-facing creator identity — deliberately separate from the
/// private onboarding `ProfileModel` (see services/api/prisma/schema.prisma's
/// CommunityProfile comment). `postCount`/`followerCount`/`followingCount`/
/// `isFollowedByViewer` are only populated when fetched via
/// `CommunityRepository.getProfile` (a single-profile read), not when a
/// profile summary is embedded in a post/comment/follow-list response.
class CommunityProfile {
  const CommunityProfile({
    required this.userId,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.isTrainer = false,
    this.postCount,
    this.followerCount,
    this.followingCount,
    this.isFollowedByViewer,
  });

  final String userId;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final bool isTrainer;
  final int? postCount;
  final int? followerCount;
  final int? followingCount;
  final bool? isFollowedByViewer;

  factory CommunityProfile.fromJson(Map<String, dynamic> json) {
    return CommunityProfile(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String? ?? 'Ascend member',
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isTrainer: json['isTrainer'] as bool? ?? false,
      postCount: json['postCount'] as int?,
      followerCount: json['followerCount'] as int?,
      followingCount: json['followingCount'] as int?,
      isFollowedByViewer: json['isFollowedByViewer'] as bool?,
    );
  }
}
