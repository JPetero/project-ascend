/// Rankings scopes — Founder Scenario 16a's full local/city/region/
/// state/national/global granularity, restored in Build Session 13
/// continuation Part D from the three-scope (FRIENDS/REGION/GLOBAL)
/// MVP. See services/api/src/modules/rankings/rankings-locality.util.ts,
/// which this mirrors.
enum RankingScope { friends, local, city, region, national, global }

String rankingScopeToJson(RankingScope scope) => scope.name.toUpperCase();

RankingScope rankingScopeFromJson(String value) =>
    RankingScope.values.firstWhere(
      (s) => s.name.toUpperCase() == value,
      orElse: () => RankingScope.global,
    );

String rankingScopeLabel(RankingScope scope) => switch (scope) {
  RankingScope.friends => 'Friends',
  RankingScope.local => 'Local',
  RankingScope.city => 'City',
  RankingScope.region => 'Region',
  RankingScope.national => 'National',
  RankingScope.global => 'Global',
};

/// Locality tiers, broadest to narrowest — mirrors the backend's
/// LOCALITY_TIER_ORDER exactly. FRIENDS and GLOBAL are not locality
/// scopes: they need no locality fields and have no tier index.
const List<RankingScope> localityTierOrder = [
  RankingScope.national,
  RankingScope.region,
  RankingScope.city,
  RankingScope.local,
];

/// -1 for FRIENDS/GLOBAL, else 0-3 (NATIONAL through LOCAL).
int localityTierIndex(RankingScope scope) => localityTierOrder.indexOf(scope);

bool isLocalityScope(RankingScope scope) => localityTierIndex(scope) >= 0;

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
/// requirement. No exact location is ever included; the locality
/// fields are user-typed coarse strings, populated from
/// localityCountry down through whichever tier `scope` requires (see
/// RankingScope's doc comment).
class RankingMyStatus {
  const RankingMyStatus({
    required this.optedIn,
    this.scope,
    this.localityCountry,
    this.localityRegion,
    this.localityCity,
    this.localityArea,
    this.season,
    this.points,
    this.activeDays,
  });

  final bool optedIn;
  final RankingScope? scope;
  final String? localityCountry;
  final String? localityRegion;
  final String? localityCity;
  final String? localityArea;
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
      localityCountry: json['localityCountry'] as String?,
      localityRegion: json['localityRegion'] as String?,
      localityCity: json['localityCity'] as String?,
      localityArea: json['localityArea'] as String?,
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
