import 'package:mobile/features/challenges/data/challenges_repository.dart';
import 'package:mobile/features/challenges/domain/challenge.dart';

Challenge sampleChallenge({
  String id = 'challenge-1',
  String creatorId = 'creator-1',
  String title = 'August step-up',
  int participantCount = 1,
  DateTime? startsAt,
  DateTime? endsAt,
}) {
  return Challenge(
    id: id,
    creatorId: creatorId,
    title: title,
    startsAt: startsAt ?? DateTime.utc(2026, 8, 1),
    endsAt: endsAt ?? DateTime.utc(2026, 8, 31),
    participantCount: participantCount,
  );
}

/// In-memory stand-in for [ChallengesRepository].
class FakeChallengesRepository implements ChallengesRepository {
  FakeChallengesRepository({
    List<Challenge>? mine,
    List<Challenge>? discoverable,
  }) : mine = mine ?? [],
       discoverable = discoverable ?? [];

  final List<Challenge> mine;
  final List<Challenge> discoverable;
  final Map<String, ChallengeDetail> detailsById = {};

  @override
  Future<Challenge> create({
    required String title,
    String? description,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final challenge = Challenge(
      id: 'challenge-${mine.length + discoverable.length}',
      creatorId: 'me',
      title: title,
      description: description,
      startsAt: startsAt,
      endsAt: endsAt,
      participantCount: 1,
    );
    mine.add(challenge);
    return challenge;
  }

  @override
  Future<List<Challenge>> listMine() async => List.unmodifiable(mine);

  @override
  Future<List<Challenge>> listDiscoverable({
    int page = 1,
    int limit = 20,
  }) async => List.unmodifiable(discoverable);

  @override
  Future<ChallengeDetail> getById(String id) async {
    if (detailsById.containsKey(id)) return detailsById[id]!;
    final challenge = [
      ...mine,
      ...discoverable,
    ].firstWhere((c) => c.id == id, orElse: () => throw Exception('not found'));
    return ChallengeDetail(
      challenge: challenge,
      isParticipant: mine.any((c) => c.id == id),
      participants: null,
    );
  }

  @override
  Future<void> join(String id) async {
    final index = discoverable.indexWhere((c) => c.id == id);
    if (index == -1) return;
    mine.add(discoverable.removeAt(index));
  }

  @override
  Future<void> leave(String id) async {
    mine.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> delete(String id) async {
    mine.removeWhere((c) => c.id == id);
    discoverable.removeWhere((c) => c.id == id);
  }
}
