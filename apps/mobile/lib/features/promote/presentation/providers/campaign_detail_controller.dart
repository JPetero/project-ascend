import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/promote_repository.dart';
import '../../domain/campaign.dart';
import 'promote_controller.dart';

class CampaignDetailState {
  const CampaignDetailState({
    this.metrics,
    this.isLoading = true,
    this.isEnding = false,
    this.error,
  });

  final CampaignMetrics? metrics;
  final bool isLoading;
  final bool isEnding;
  final String? error;

  CampaignDetailState copyWith({
    CampaignMetrics? metrics,
    bool? isLoading,
    bool? isEnding,
    String? error,
    bool clearError = false,
  }) {
    return CampaignDetailState(
      metrics: metrics ?? this.metrics,
      isLoading: isLoading ?? this.isLoading,
      isEnding: isEnding ?? this.isEnding,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CampaignDetailController extends StateNotifier<CampaignDetailState> {
  CampaignDetailController({
    required PromoteRepository repository,
    required this.campaignId,
  }) : _repository = repository,
       super(const CampaignDetailState()) {
    load();
  }

  final PromoteRepository _repository;
  final String campaignId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final metrics = await _repository.getMetrics(campaignId);
      state = CampaignDetailState(metrics: metrics, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<bool> end() async {
    state = state.copyWith(isEnding: true, clearError: true);
    try {
      await _repository.endCampaign(campaignId);
      await load();
      return true;
    } catch (error) {
      state = state.copyWith(isEnding: false, error: error.toString());
      return false;
    }
  }
}

final campaignDetailControllerProvider = StateNotifierProvider.family
    .autoDispose<CampaignDetailController, CampaignDetailState, String>((
      ref,
      campaignId,
    ) {
      return CampaignDetailController(
        repository: ref.watch(promoteRepositoryProvider),
        campaignId: campaignId,
      );
    });
