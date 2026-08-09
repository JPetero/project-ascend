import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/community_repository.dart';
import '../../domain/content_analytics.dart';
import 'community_feed_controller.dart';

class ContentAnalyticsState {
  const ContentAnalyticsState({
    this.analytics,
    this.isLoading = true,
    this.error,
  });

  final ContentAnalytics? analytics;
  final bool isLoading;
  final String? error;

  ContentAnalyticsState copyWith({
    ContentAnalytics? analytics,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ContentAnalyticsState(
      analytics: analytics ?? this.analytics,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ContentAnalyticsController extends StateNotifier<ContentAnalyticsState> {
  ContentAnalyticsController({required CommunityRepository repository})
    : _repository = repository,
      super(const ContentAnalyticsState()) {
    load();
  }

  final CommunityRepository _repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final analytics = await _repository.getMyContentAnalytics();
      state = ContentAnalyticsState(analytics: analytics, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }
}

final contentAnalyticsControllerProvider =
    StateNotifierProvider.autoDispose<
      ContentAnalyticsController,
      ContentAnalyticsState
    >((ref) {
      return ContentAnalyticsController(
        repository: ref.watch(communityRepositoryProvider),
      );
    });
