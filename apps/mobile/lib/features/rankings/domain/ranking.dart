/// Rankings scopes — a deliberate MVP simplification of Founder Scenario
/// 16a's local/city/region/state/national/global granularity down to
/// three: people you follow, a self-typed coarse region label, and
/// everyone. See services/api/src/modules/rankings/rankings.service.ts.
enum RankingScope { friends, region, global }

String rankingScopeToJson(RankingScope scope) => scope.name.toUpperCase();

RankingScope rankingScopeFromJson(String value) =>
    RankingScope.values.firstWhere(
      (s) => s.name.toUpperCase() == value,
      orElse: () => RankingScope.global,
    );

class RankingSeason {
  const RankingSeason({
    required this.id,
    required this.label,
    required this.startsAt,
    required this.endsAt,
  });

  final String id;
  final String label;
  final DateTime startsAt;
  final DateTime endsAt;

  factory RankingSeason.fromJson(Map<String, dynamic> json) {
    return RankingSeason(
      id: json['id'] as String,
      label: json['label'] as String,
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
    );
  }
}

/// The caller's own opt-in state — off (`optedIn: false`) unless the
/// caller has explicitly opted in, per Scenario 16a's off-by-default
/// requirement. No exact location is ever included; `regionLabel` is a
/// user-typed coarse string.
class RankingMyStatus {
  const RankingMyStatus({
    required this.optedIn,
    this.scope,
    this.regionLabel,
    this.season,
    this.points,
    this.activeDays,
  });

  final bool optedIn;
  final RankingScope? scope;
  final String? regionLabel;
  final RankingSeason? season;
  final int? points;
  final int? activeDays;

  factory RankingMyStatus.fromJson(Map<String, dynamic> json) {
    if (json['optedIn'] != true) {
      return const RankingMyStatus(optedIn: false);
    }
    return RankingMyStatus(
      optedIn: true,
      scope: rankingScopeFromJson(json['scope'] as String),
      regionLabel: json['regionLabel'] as String?,
      season: RankingSeason.fromJson(json['season'] as Map<String, dynamic>),
      points: json['points'] as int,
      activeDays: json['activeDays'] as int,
    );
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    this.displayName,
    this.avatarUrl,
    required this.points,
    required this.activeDays,
    required this.isViewer,
  });

  final int rank;
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final int points;
  final int activeDays;
  final bool isViewer;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      points: json['points'] as int,
      activeDays: json['activeDays'] as int,
      isViewer: json['isViewer'] as bool,
    );
  }
}

class LeaderboardPage {
  const LeaderboardPage({required this.entries, required this.total});

  final List<LeaderboardEntry> entries;
  final int total;

  factory LeaderboardPage.fromJson(Map<String, dynamic> json) {
    final items = json['data'] as List<dynamic>;
    final meta = json['meta'] as Map<String, dynamic>;
    return LeaderboardPage(
      entries: items
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: meta['total'] as int,
    );
  }
}
