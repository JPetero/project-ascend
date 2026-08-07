import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/community_repository.dart';
import '../../domain/community_profile.dart';
import 'community_feed_controller.dart';

class CommunityProfileState {
  const CommunityProfileState({
    this.profile,
    this.isLoading = true,
    this.isMutating = false,
    this.error,
  });

  final CommunityProfile? profile;
  final bool isLoading;
  final bool isMutating;
  final String? error;

  CommunityProfileState copyWith({
    CommunityProfile? profile,
    bool? isLoading,
    bool? isMutating,
    String? error,
    bool clearError = false,
  }) {
    return CommunityProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Another user's (or the caller's own) public Community profile, plus
/// follow/block actions. Blocking or unblocking invalidates the profile
/// so a re-fetch reflects the new (or newly-hidden, via a 404) state —
/// see `CommunityService.assertNotBlockedEitherWay` on the backend.
class CommunityProfileController extends StateNotifier<CommunityProfileState> {
  CommunityProfileController({
    required CommunityRepository repository,
    required this.userId,
  }) : _repository = repository,
       super(const CommunityProfileState()) {
    load();
  }

  final CommunityRepository _repository;
  final String userId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _repository.getProfile(userId);
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> toggleFollow() async {
    final profile = state.profile;
    if (profile == null) return;
    final wasFollowing = profile.isFollowedByViewer ?? false;
    state = state.copyWith(isMutating: true);
    try {
      wasFollowing
          ? await _repository.unfollow(userId)
          : await _repository.follow(userId);
      await load();
    } catch (error) {
      state = state.copyWith(isMutating: false, error: error.toString());
    }
  }

  Future<bool> block() async {
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      await _repository.block(userId);
      state = state.copyWith(isMutating: false);
      return true;
    } catch (error) {
      state = state.copyWith(isMutating: false, error: error.toString());
      return false;
    }
  }

  Future<bool> report(String reason) async {
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      await _repository.report(
        targetType: 'PROFILE',
        targetId: userId,
        reason: reason,
      );
      state = state.copyWith(isMutating: false);
      return true;
    } catch (error) {
      state = state.copyWith(isMutating: false, error: error.toString());
      return false;
    }
  }
}

final communityProfileControllerProvider = StateNotifierProvider.family
    .autoDispose<CommunityProfileController, CommunityProfileState, String>((
      ref,
      userId,
    ) {
      return CommunityProfileController(
        repository: ref.watch(communityRepositoryProvider),
        userId: userId,
      );
    });
