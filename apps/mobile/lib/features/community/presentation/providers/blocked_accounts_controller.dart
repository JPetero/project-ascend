import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/community_repository.dart';
import '../../domain/blocked_user.dart';
import 'community_feed_controller.dart';

class BlockedAccountsState {
  const BlockedAccountsState({
    this.blocked = const [],
    this.isLoading = true,
    this.error,
  });

  final List<BlockedUser> blocked;
  final bool isLoading;
  final String? error;

  BlockedAccountsState copyWith({
    List<BlockedUser>? blocked,
    bool? isLoading,
    String? error,
  }) {
    return BlockedAccountsState(
      blocked: blocked ?? this.blocked,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Backs the Privacy Center's "Blocked accounts" list (Build Session 12
/// Part 12-14) — the first place a blocked user could previously only be
/// unblocked from was the exact profile screen used to block them.
class BlockedAccountsController extends StateNotifier<BlockedAccountsState> {
  BlockedAccountsController({required CommunityRepository repository})
    : _repository = repository,
      super(const BlockedAccountsState()) {
    refresh();
  }

  final CommunityRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final blocked = await _repository.listBlocked();
      state = BlockedAccountsState(blocked: blocked, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<bool> unblock(String userId) async {
    final previous = state.blocked;
    state = state.copyWith(
      blocked: previous.where((b) => b.userId != userId).toList(),
    );
    try {
      await _repository.unblock(userId);
      return true;
    } catch (error) {
      state = state.copyWith(blocked: previous, error: error.toString());
      return false;
    }
  }
}

final blockedAccountsControllerProvider =
    StateNotifierProvider.autoDispose<
      BlockedAccountsController,
      BlockedAccountsState
    >((ref) {
      return BlockedAccountsController(
        repository: ref.watch(communityRepositoryProvider),
      );
    });
