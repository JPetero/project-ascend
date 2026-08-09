/// One account the caller has blocked (Build Session 12 Part 12-14 —
/// Privacy Center's "Blocked accounts" list). [displayName]/[avatarUrl]
/// are null when the blocked account never set up a community profile.
class BlockedUser {
  const BlockedUser({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    required this.blockedAt,
  });

  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final DateTime blockedAt;

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      blockedAt: DateTime.parse(json['blockedAt'] as String),
    );
  }
}
