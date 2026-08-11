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

/// S13 Part 8 — which single domain a leaderboard is scored by, mirroring
/// services/api/src/common/scoring/ranking-category.ts exactly. OVERALL
/// keeps the pre-existing blended score; the other three isolate one of
/// the domains a [LeaderboardEntry]'s provenance breakdown already
/// reports for every entry, regardless of which category is selected.
enum RankingCategory { overall, strength, cardio, nutrition }

String rankingCategoryToJson(RankingCategory category) =>
    category.name.toUpperCase();

RankingCategory rankingCategoryFromJson(String value) =>
    RankingCategory.values.firstWhere(
      (c) => c.name.toUpperCase() == value,
      orElse: () => RankingCategory.overall,
    );

String rankingCategoryLabel(RankingCategory category) => switch (category) {
  RankingCategory.overall => 'Overall',
  RankingCategory.strength => 'Strength',
  RankingCategory.cardio => 'Cardio',
  RankingCategory.nutrition => 'Nutrition',
};

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
    this.strengthDays,
    this.cardioDays,
    this.nutritionDays,
    this.verifiedCardioDays,
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
  final int? strengthDays;
  final int? cardioDays;
  final int? nutritionDays;
  final int? verifiedCardioDays;

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
      strengthDays: json['strengthDays'] as int?,
      cardioDays: json['cardioDays'] as int?,
      nutritionDays: json['nutritionDays'] as int?,
      verifiedCardioDays: json['verifiedCardioDays'] as int?,
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
    this.strengthDays = 0,
    this.cardioDays = 0,
    this.nutritionDays = 0,
    this.verifiedCardioDays = 0,
  });

  final int rank;
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final int points;
  final int activeDays;
  final bool isViewer;
  // Provenance breakdown (S13 Part 8) — always present regardless of
  // which category the leaderboard is currently sorted by, so a
  // ranking is never a black-box number. verifiedCardioDays is the
  // subset of cardioDays recorded via LIVE_GPS/WEARABLE rather than
  // typed in manually.
  final int strengthDays;
  final int cardioDays;
  final int nutritionDays;
  final int verifiedCardioDays;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      points: json['points'] as int,
      activeDays: json['activeDays'] as int,
      isViewer: json['isViewer'] as bool,
      strengthDays: json['strengthDays'] as int? ?? 0,
      cardioDays: json['cardioDays'] as int? ?? 0,
      nutritionDays: json['nutritionDays'] as int? ?? 0,
      verifiedCardioDays: json['verifiedCardioDays'] as int? ?? 0,
    );
  }
}

class LeaderboardPage {
  const LeaderboardPage({
    required this.entries,
    required this.total,
    required this.category,
  });

  final List<LeaderboardEntry> entries;
  final int total;
  final RankingCategory category;

  factory LeaderboardPage.fromJson(Map<String, dynamic> json) {
    final items = json['data'] as List<dynamic>;
    final meta = json['meta'] as Map<String, dynamic>;
    return LeaderboardPage(
      entries: items
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: meta['total'] as int,
      category: meta['category'] != null
          ? rankingCategoryFromJson(meta['category'] as String)
          : RankingCategory.overall,
    );
  }
}
