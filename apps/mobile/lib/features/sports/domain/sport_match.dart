/// One entry from `GET /sports` — Build Session 12 Part 23-24's
/// sport-selector needs the real, current list rather than a hardcoded
/// single option.
class SportSummary {
  const SportSummary({required this.code, required this.name});

  final String code;
  final String name;

  factory SportSummary.fromJson(Map<String, dynamic> json) {
    return SportSummary(
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }
}

enum SportMatchStatus {
  created,
  invited,
  ready,
  inProgress,
  scorePending,
  disputed,
  confirmed,
  canceled,
  void_,
}

SportMatchStatus sportMatchStatusFromJson(String value) {
  switch (value) {
    case 'INVITED':
      return SportMatchStatus.invited;
    case 'READY':
      return SportMatchStatus.ready;
    case 'IN_PROGRESS':
      return SportMatchStatus.inProgress;
    case 'SCORE_PENDING':
      return SportMatchStatus.scorePending;
    case 'DISPUTED':
      return SportMatchStatus.disputed;
    case 'CONFIRMED':
      return SportMatchStatus.confirmed;
    case 'CANCELED':
      return SportMatchStatus.canceled;
    case 'VOID':
      return SportMatchStatus.void_;
    default:
      return SportMatchStatus.created;
  }
}

enum SportMatchParticipantStatus { invited, accepted, declined, ready, left }

SportMatchParticipantStatus sportMatchParticipantStatusFromJson(String value) {
  switch (value) {
    case 'ACCEPTED':
      return SportMatchParticipantStatus.accepted;
    case 'DECLINED':
      return SportMatchParticipantStatus.declined;
    case 'READY':
      return SportMatchParticipantStatus.ready;
    case 'LEFT':
      return SportMatchParticipantStatus.left;
    default:
      return SportMatchParticipantStatus.invited;
  }
}

class SportMatchParticipant {
  const SportMatchParticipant({
    required this.id,
    required this.userId,
    required this.status,
  });

  final String id;
  final String userId;
  final SportMatchParticipantStatus status;

  factory SportMatchParticipant.fromJson(Map<String, dynamic> json) {
    return SportMatchParticipant(
      id: json['id'] as String,
      userId: json['userId'] as String,
      status: sportMatchParticipantStatusFromJson(json['status'] as String),
    );
  }
}

/// Scores are relative to the proposer, never a fixed home/away slot —
/// see the backend's SportScoreProposal schema comment.
class SportScoreProposal {
  const SportScoreProposal({
    required this.id,
    required this.proposedById,
    required this.proposerScore,
    required this.opponentScore,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String proposedById;
  final int proposerScore;
  final int opponentScore;
  final String status;
  final DateTime createdAt;

  factory SportScoreProposal.fromJson(Map<String, dynamic> json) {
    return SportScoreProposal(
      id: json['id'] as String,
      proposedById: json['proposedById'] as String,
      proposerScore: json['proposerScore'] as int,
      opponentScore: json['opponentScore'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class SportMatchDispute {
  const SportMatchDispute({
    required this.id,
    required this.raisedById,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String raisedById;
  final String reason;
  final DateTime createdAt;

  factory SportMatchDispute.fromJson(Map<String, dynamic> json) {
    return SportMatchDispute(
      id: json['id'] as String,
      raisedById: json['raisedById'] as String,
      reason: json['reason'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// A confirmed 1v1 sports match — Build Session 8 Part 10. A proposed
/// score only counts once the *other* participant confirms it; see
/// services/api/prisma/schema.prisma's Sports Match System comment for
/// the full dual-confirmation and dispute flow.
class SportMatch {
  const SportMatch({
    required this.id,
    required this.createdById,
    required this.status,
    this.flagged = false,
    required this.createdAt,
    this.sportCode,
    this.sportName,
    this.participants = const [],
    this.scoreProposals = const [],
    this.disputes = const [],
  });

  final String id;
  final String createdById;
  final SportMatchStatus status;
  final bool flagged;
  final DateTime createdAt;
  // Build Session 12 Part 23-24 — a second sport (Table Tennis) exists
  // now, so the match's own sport can no longer be assumed; parsed from
  // the `sport` object every list/detail response already includes.
  final String? sportCode;
  final String? sportName;
  final List<SportMatchParticipant> participants;
  final List<SportScoreProposal> scoreProposals;
  final List<SportMatchDispute> disputes;

  factory SportMatch.fromJson(Map<String, dynamic> json) {
    final participantsJson = json['participants'] as List<dynamic>?;
    final proposalsJson = json['scoreProposals'] as List<dynamic>?;
    final disputesJson = json['disputes'] as List<dynamic>?;
    final sportJson = json['sport'] as Map<String, dynamic>?;
    return SportMatch(
      id: json['id'] as String,
      createdById: json['createdById'] as String,
      status: sportMatchStatusFromJson(json['status'] as String),
      flagged: json['flagged'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      sportCode: sportJson?['code'] as String?,
      sportName: sportJson?['name'] as String?,
      participants:
          participantsJson
              ?.map(
                (p) =>
                    SportMatchParticipant.fromJson(p as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      scoreProposals:
          proposalsJson
              ?.map(
                (p) => SportScoreProposal.fromJson(p as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      disputes:
          disputesJson
              ?.map(
                (d) => SportMatchDispute.fromJson(d as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }
}

/// Elo-like, with a provisional period — see SportRating's backend
/// schema comment.
class SportRating {
  const SportRating({
    required this.rating,
    required this.isProvisional,
    required this.matchesPlayed,
  });

  final double rating;
  final bool isProvisional;
  final int matchesPlayed;

  factory SportRating.fromJson(Map<String, dynamic> json) {
    return SportRating(
      rating: (json['rating'] as num).toDouble(),
      isProvisional: json['isProvisional'] as bool? ?? true,
      matchesPlayed: json['matchesPlayed'] as int? ?? 0,
    );
  }
}

class SportLeaderboardEntry {
  const SportLeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.rating,
    required this.isProvisional,
    required this.matchesPlayed,
  });

  final String userId;
  final String displayName;
  final double rating;
  final bool isProvisional;
  final int matchesPlayed;

  factory SportLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return SportLeaderboardEntry(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String? ?? 'Ascend member',
      rating: (json['rating'] as num).toDouble(),
      isProvisional: json['isProvisional'] as bool? ?? true,
      matchesPlayed: json['matchesPlayed'] as int? ?? 0,
    );
  }
}
