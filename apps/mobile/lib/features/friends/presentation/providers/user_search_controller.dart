import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../community/domain/community_profile.dart';
import '../../data/friends_repository.dart';
import 'friends_controller.dart';

class UserSearchState {
  const UserSearchState({
    this.results = const [],
    this.isLoading = false,
    this.hasSearched = false,
    this.error,
  });

  final List<CommunityProfile> results;
  final bool isLoading;
  final bool hasSearched;
  final String? error;

  UserSearchState copyWith({
    List<CommunityProfile>? results,
    bool? isLoading,
    bool? hasSearched,
    String? error,
    bool clearError = false,
  }) {
    return UserSearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      hasSearched: hasSearched ?? this.hasSearched,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class UserSearchController extends StateNotifier<UserSearchState> {
  UserSearchController({required FriendsRepository repository})
    : _repository = repository,
      super(const UserSearchState());

  final FriendsRepository _repository;

  Future<void> search(String query) async {
    if (query.trim().length < 2) {
      state = const UserSearchState();
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await _repository.searchUsers(query.trim());
      state = UserSearchState(results: results, hasSearched: true);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }
}

final userSearchControllerProvider =
    StateNotifierProvider.autoDispose<UserSearchController, UserSearchState>((
      ref,
    ) {
      return UserSearchController(
        repository: ref.watch(friendsRepositoryProvider),
      );
    });
