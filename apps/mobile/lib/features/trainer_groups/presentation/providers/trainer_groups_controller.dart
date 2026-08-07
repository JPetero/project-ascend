import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/trainer_groups_repository.dart';
import '../../domain/trainer_group.dart';

final trainerGroupsRepositoryProvider = Provider<TrainerGroupsRepository>((
  ref,
) {
  return TrainerGroupsRepository(apiClient: ref.watch(apiClientProvider));
});

class TrainerGroupsState {
  const TrainerGroupsState({
    this.groups = const [],
    this.invitations = const [],
    this.isLoading = true,
    this.error,
  });

  final List<TrainerGroup> groups;
  final List<TrainerGroupInvitation> invitations;
  final bool isLoading;
  final String? error;

  TrainerGroupsState copyWith({
    List<TrainerGroup>? groups,
    List<TrainerGroupInvitation>? invitations,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TrainerGroupsState(
      groups: groups ?? this.groups,
      invitations: invitations ?? this.invitations,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// The groups the caller belongs to, plus their pending invitations — the
/// two lists a Trainer Groups home screen needs. See
/// packages/docs/product/user-scenario-bible.md Scenario 24.
class TrainerGroupsController extends StateNotifier<TrainerGroupsState> {
  TrainerGroupsController({required TrainerGroupsRepository repository})
    : _repository = repository,
      super(const TrainerGroupsState()) {
    refresh();
  }

  final TrainerGroupsRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _repository.listMyGroups(),
        _repository.listMyInvitations(),
      ]);
      state = TrainerGroupsState(
        groups: results[0] as List<TrainerGroup>,
        invitations: results[1] as List<TrainerGroupInvitation>,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<bool> acceptInvitation(String invitationId) async {
    try {
      await _repository.acceptInvitation(invitationId);
      await refresh();
      return true;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return false;
    }
  }

  Future<bool> declineInvitation(String invitationId) async {
    try {
      await _repository.declineInvitation(invitationId);
      state = state.copyWith(
        invitations: state.invitations
            .where((i) => i.id != invitationId)
            .toList(),
      );
      return true;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return false;
    }
  }
}

final trainerGroupsControllerProvider =
    StateNotifierProvider<TrainerGroupsController, TrainerGroupsState>((ref) {
      return TrainerGroupsController(
        repository: ref.watch(trainerGroupsRepositoryProvider),
      );
    });
