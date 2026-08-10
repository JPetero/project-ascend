import 'package:mobile/features/rankings/domain/ranking.dart';
import 'package:mobile/features/sports/data/sports_repository.dart';
import 'package:mobile/features/sports/domain/sport_match.dart';

SportMatchParticipant sampleSportParticipant({
  String id = 'participant-1',
  String userId = 'user-1',
  SportMatchParticipantStatus status = SportMatchParticipantStatus.accepted,
}) {
  return SportMatchParticipant(id: id, userId: userId, status: status);
}

SportMatch sampleSportMatch({
  String id = 'match-1',
  String createdById = 'user-1',
  SportMatchStatus status = SportMatchStatus.invited,
  bool flagged = false,
  String sportCode = SportsRepository.badmintonCode,
  String sportName = 'Badminton',
  List<SportMatchParticipant> participants = const [],
  List<SportScoreProposal> scoreProposals = const [],
}) {
  return SportMatch(
    id: id,
    createdById: createdById,
    status: status,
    flagged: flagged,
    createdAt: DateTime.utc(2026, 8, 7),
    sportCode: sportCode,
    sportName: sportName,
    participants: participants,
    scoreProposals: scoreProposals,
  );
}

/// In-memory stand-in for [SportsRepository]. `'user-1'` is the signed-in
/// test user's id (see FakeAuthRepository).
class FakeSportsRepository implements SportsRepository {
  FakeSportsRepository({
    List<SportMatch>? matches,
    SportRating? rating,
    Map<RankingScope, List<SportLeaderboardEntry>>? leaderboards,
  }) : matches = matches ?? [],
       rating =
           rating ??
           const SportRating(
             rating: 1500,
             isProvisional: true,
             matchesPlayed: 0,
           ),
       leaderboards = leaderboards ?? {};

  final List<SportMatch> matches;
  SportRating rating;
  final Map<RankingScope, List<SportLeaderboardEntry>> leaderboards;
  String? lastDisputeReason;
  RankingScope? lastLeaderboardScope;

  @override
  Future<List<SportMatch>> listMine() async => List.unmodifiable(matches);

  @override
  Future<List<SportSummary>> listSports() async => const [
    SportSummary(code: SportsRepository.badmintonCode, name: 'Badminton'),
    SportSummary(code: SportsRepository.tableTennisCode, name: 'Table Tennis'),
  ];

  @override
  Future<SportMatch> createMatch({
    required String opponentId,
    String sportCode = SportsRepository.badmintonCode,
  }) async {
    final match = sampleSportMatch(
      id: 'match-${matches.length + 1}',
      createdById: 'user-1',
      status: SportMatchStatus.invited,
      sportCode: sportCode,
      sportName: sportCode == SportsRepository.tableTennisCode
          ? 'Table Tennis'
          : 'Badminton',
      participants: [
        sampleSportParticipant(id: 'p-host', userId: 'user-1'),
        sampleSportParticipant(
          id: 'p-$opponentId',
          userId: opponentId,
          status: SportMatchParticipantStatus.invited,
        ),
      ],
    );
    matches.add(match);
    return match;
  }

  @override
  Future<SportMatch> getById(String matchId) async =>
      matches.firstWhere((m) => m.id == matchId);

  @override
  Future<SportMatch> accept(String matchId) =>
      _updateMyStatus(matchId, SportMatchParticipantStatus.accepted);

  @override
  Future<SportMatch> decline(String matchId) async {
    await _updateMyStatus(matchId, SportMatchParticipantStatus.declined);
    return _updateStatus(matchId, SportMatchStatus.canceled);
  }

  @override
  Future<SportMatch> ready(String matchId) async {
    await _updateMyStatus(matchId, SportMatchParticipantStatus.ready);
    final match = matches.firstWhere((m) => m.id == matchId);
    final bothReady = match.participants.every(
      (p) => p.status == SportMatchParticipantStatus.ready,
    );
    return bothReady ? _updateStatus(matchId, SportMatchStatus.ready) : match;
  }

  @override
  Future<SportMatch> start(String matchId) =>
      _updateStatus(matchId, SportMatchStatus.inProgress);

  @override
  Future<SportMatch> proposeScore(
    String matchId, {
    required int proposerScore,
    required int opponentScore,
  }) async {
    final index = matches.indexWhere((m) => m.id == matchId);
    final match = matches[index];
    matches[index] = sampleSportMatch(
      id: match.id,
      createdById: match.createdById,
      status: SportMatchStatus.scorePending,
      flagged: match.flagged,
      sportCode: match.sportCode ?? SportsRepository.badmintonCode,
      sportName: match.sportName ?? 'Badminton',
      participants: match.participants,
      scoreProposals: [
        SportScoreProposal(
          id: 'proposal-1',
          proposedById: 'user-1',
          proposerScore: proposerScore,
          opponentScore: opponentScore,
          status: 'PENDING',
          createdAt: DateTime.utc(2026, 8, 7),
        ),
        ...match.scoreProposals,
      ],
    );
    return matches[index];
  }

  @override
  Future<SportMatch> confirmScore(String matchId) =>
      _updateStatus(matchId, SportMatchStatus.confirmed);

  @override
  Future<SportMatch> disputeScore(String matchId, String reason) async {
    lastDisputeReason = reason;
    return _updateStatus(matchId, SportMatchStatus.disputed);
  }

  @override
  Future<SportMatch> cancel(String matchId) =>
      _updateStatus(matchId, SportMatchStatus.canceled);

  @override
  Future<SportMatch> voidMatch(String matchId) =>
      _updateStatus(matchId, SportMatchStatus.void_);

  @override
  Future<SportRating> getMyRating({
    String sportCode = SportsRepository.badmintonCode,
  }) async => rating;

  @override
  Future<List<SportLeaderboardEntry>> leaderboard({
    String sportCode = SportsRepository.badmintonCode,
    RankingScope scope = RankingScope.global,
  }) async {
    lastLeaderboardScope = scope;
    return leaderboards[scope] ?? const [];
  }

  Future<SportMatch> _updateStatus(
    String matchId,
    SportMatchStatus status,
  ) async {
    final index = matches.indexWhere((m) => m.id == matchId);
    final match = matches[index];
    matches[index] = sampleSportMatch(
      id: match.id,
      createdById: match.createdById,
      status: status,
      flagged: match.flagged,
      sportCode: match.sportCode ?? SportsRepository.badmintonCode,
      sportName: match.sportName ?? 'Badminton',
      participants: match.participants,
      scoreProposals: match.scoreProposals,
    );
    return matches[index];
  }

  Future<SportMatch> _updateMyStatus(
    String matchId,
    SportMatchParticipantStatus status,
  ) async {
    final index = matches.indexWhere((m) => m.id == matchId);
    final match = matches[index];
    matches[index] = sampleSportMatch(
      id: match.id,
      createdById: match.createdById,
      status: match.status,
      flagged: match.flagged,
      sportCode: match.sportCode ?? SportsRepository.badmintonCode,
      sportName: match.sportName ?? 'Badminton',
      participants: [
        for (final p in match.participants)
          if (p.userId == 'user-1')
            sampleSportParticipant(id: p.id, userId: p.userId, status: status)
          else
            p,
      ],
      scoreProposals: match.scoreProposals,
    );
    return matches[index];
  }
}
