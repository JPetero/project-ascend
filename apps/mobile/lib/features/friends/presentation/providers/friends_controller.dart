import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../community/domain/community_profile.dart';
import '../../data/friends_repository.dart';
import '../../domain/friend_request.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository(apiClient: ref.watch(apiClientProvider));
});

class FriendsState {
  const FriendsState({
    this.friends = const [],
    this.incoming = const [],
    this.outgoing = const [],
    this.isLoading = true,
    this.error,
  });

  final List<CommunityProfile> friends;
  final List<FriendRequest> incoming;
  final List<FriendRequest> outgoing;
  final bool isLoading;
  final String? error;

  FriendsState copyWith({
    List<CommunityProfile>? friends,
    List<FriendRequest>? incoming,
    List<FriendRequest>? outgoing,
    bool? isLoading,
    String? error,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      incoming: incoming ?? this.incoming,
      outgoing: outgoing ?? this.outgoing,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Friends, incoming requests, and outgoing requests, loaded together
/// since the Friends screen shows all three — Build Session 8 Part 7.
class FriendsController extends StateNotifier<FriendsState> {
  FriendsController({required FriendsRepository repository})
    : _repository = repository,
      super(const FriendsState()) {
    refresh();
  }

  final FriendsRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        _repository.listFriends(),
        _repository.listIncomingRequests(),
        _repository.listOutgoingRequests(),
      ]);
      state = FriendsState(
        friends: results[0] as List<CommunityProfile>,
        incoming: results[1] as List<FriendRequest>,
        outgoing: results[2] as List<FriendRequest>,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> sendRequest(String recipientId) async {
    await _repository.sendRequest(recipientId);
    await refresh();
  }

  Future<void> acceptRequest(String requestId) async {
    await _repository.acceptRequest(requestId);
    await refresh();
  }

  Future<void> declineRequest(String requestId) async {
    await _repository.declineRequest(requestId);
    await refresh();
  }

  Future<void> cancelRequest(String requestId) async {
    await _repository.cancelRequest(requestId);
    await refresh();
  }

  Future<void> removeFriend(String friendId) async {
    await _repository.removeFriend(friendId);
    await refresh();
  }
}

final friendsControllerProvider =
    StateNotifierProvider<FriendsController, FriendsState>((ref) {
      return FriendsController(
        repository: ref.watch(friendsRepositoryProvider),
      );
    });
