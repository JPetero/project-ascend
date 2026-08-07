import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/promote_repository.dart';
import '../../domain/campaign.dart';

final promoteRepositoryProvider = Provider<PromoteRepository>((ref) {
  return PromoteRepository(apiClient: ref.watch(apiClientProvider));
});

class PromoteState {
  const PromoteState({
    this.campaigns = const [],
    this.isLoading = true,
    this.error,
  });

  final List<Campaign> campaigns;
  final bool isLoading;
  final String? error;

  PromoteState copyWith({
    List<Campaign>? campaigns,
    bool? isLoading,
    String? error,
  }) {
    return PromoteState(
      campaigns: campaigns ?? this.campaigns,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// The caller's own Ascend Promote campaigns.
class PromoteController extends StateNotifier<PromoteState> {
  PromoteController({required PromoteRepository repository})
    : _repository = repository,
      super(const PromoteState()) {
    refresh();
  }

  final PromoteRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final campaigns = await _repository.listMine();
      state = PromoteState(campaigns: campaigns, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }
}

final promoteControllerProvider =
    StateNotifierProvider<PromoteController, PromoteState>((ref) {
      return PromoteController(
        repository: ref.watch(promoteRepositoryProvider),
      );
    });
