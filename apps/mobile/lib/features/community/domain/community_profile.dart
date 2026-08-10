/// Who besides the owner can view a Community profile — mirrors
/// services/api/prisma/schema.prisma's CommunityProfileVisibility, added
/// Build Session 9 Part 2. FRIENDS uses the real mutual friend graph,
/// distinct from one-directional Community Follow.
enum CommunityProfileVisibility { private_, friends, followers, public_ }

String communityProfileVisibilityToJson(CommunityProfileVisibility value) =>
    switch (value) {
      CommunityProfileVisibility.private_ => 'PRIVATE',
      CommunityProfileVisibility.friends => 'FRIENDS',
      CommunityProfileVisibility.followers => 'FOLLOWERS',
      CommunityProfileVisibility.public_ => 'PUBLIC',
    };

CommunityProfileVisibility communityProfileVisibilityFromJson(String value) =>
    switch (value) {
      'PRIVATE' => CommunityProfileVisibility.private_,
      'FRIENDS' => CommunityProfileVisibility.friends,
      'FOLLOWERS' => CommunityProfileVisibility.followers,
      _ => CommunityProfileVisibility.public_,
    };

String communityProfileVisibilityLabel(CommunityProfileVisibility value) =>
    switch (value) {
      CommunityProfileVisibility.private_ => 'Only me',
      CommunityProfileVisibility.friends => 'Friends',
      CommunityProfileVisibility.followers => 'Followers',
      CommunityProfileVisibility.public_ => 'Everyone',
    };

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
    this.coverUrl,
    this.isTrainer = false,
    this.verifiedTrainer = false,
    this.visibility = CommunityProfileVisibility.public_,
    this.postCount,
    this.followerCount,
    this.followingCount,
    this.isFollowedByViewer,
  });

  final String userId;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final String? coverUrl;
  final bool isTrainer;
  // Set only by an admin approving a TrainerVerificationApplication (Build
  // Session 12 Part 25-26) — never self-service, never derived from
  // [isTrainer]. See services/api's CommunityProfile.verifiedTrainer.
  final bool verifiedTrainer;
  final CommunityProfileVisibility visibility;
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
      coverUrl: json['coverUrl'] as String?,
      isTrainer: json['isTrainer'] as bool? ?? false,
      verifiedTrainer: json['verifiedTrainer'] as bool? ?? false,
      visibility: json['visibility'] != null
          ? communityProfileVisibilityFromJson(json['visibility'] as String)
          : CommunityProfileVisibility.public_,
      postCount: json['postCount'] as int?,
      followerCount: json['followerCount'] as int?,
      followingCount: json['followingCount'] as int?,
      isFollowedByViewer: json['isFollowedByViewer'] as bool?,
    );
  }
}
