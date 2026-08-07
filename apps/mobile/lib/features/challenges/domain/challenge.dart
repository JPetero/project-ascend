/// A time-boxed, join-by-choice challenge — Founder Scenario 21's
/// Rankings/Challenges MVP. See
/// services/api/src/modules/challenges/challenges.service.ts.
class Challenge {
  const Challenge({
    required this.id,
    required this.creatorId,
    required this.title,
    this.description,
    required this.startsAt,
    required this.endsAt,
    required this.participantCount,
  });

  final String id;
  final String creatorId;
  final String title;
  final String? description;
  final DateTime startsAt;
  final DateTime endsAt;
  final int participantCount;

  bool get hasEnded => DateTime.now().isAfter(endsAt);

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      creatorId: json['creatorId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      participantCount: json['participantCount'] as int,
    );
  }
}

/// Progress is measured the same non-gameable "active days" way as
/// Rankings (see common/scoring/activity-scoring.util.ts on the
/// backend) — never a raw-volume metric.
class ChallengeParticipantProgress {
  const ChallengeParticipantProgress({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    required this.activeDays,
    required this.totalDays,
  });

  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final int activeDays;
  final int totalDays;

  factory ChallengeParticipantProgress.fromJson(Map<String, dynamic> json) {
    return ChallengeParticipantProgress(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      activeDays: json['activeDays'] as int,
      totalDays: json['totalDays'] as int,
    );
  }
}

/// Per-participant progress is only ever populated for a participant —
/// see `ChallengesService.getById`'s privacy gate on the backend.
class ChallengeDetail {
  const ChallengeDetail({
    required this.challenge,
    required this.isParticipant,
    this.participants,
  });

  final Challenge challenge;
  final bool isParticipant;
  final List<ChallengeParticipantProgress>? participants;

  factory ChallengeDetail.fromJson(Map<String, dynamic> json) {
    final participantsJson = json['participants'] as List<dynamic>?;
    return ChallengeDetail(
      challenge: Challenge.fromJson(json),
      isParticipant: json['isParticipant'] as bool,
      participants: participantsJson
          ?.map(
            (p) => ChallengeParticipantProgress.fromJson(
              p as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
