import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/entitlements/capability.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/subscriptions_repository.dart';
import '../../domain/subscription_status.dart';

final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>((
  ref,
) {
  return SubscriptionsRepository(apiClient: ref.watch(apiClientProvider));
});

class SubscriptionState {
  const SubscriptionState({
    this.status,
    this.pricing = const [],
    this.isLoading = true,
    this.isApplying = false,
    this.error,
  });

  final SubscriptionStatus? status;
  final List<PricingPoint> pricing;
  final bool isLoading;
  final bool isApplying;
  final String? error;

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    List<PricingPoint>? pricing,
    bool? isLoading,
    bool? isApplying,
    String? error,
    bool clearError = false,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      pricing: pricing ?? this.pricing,
      isLoading: isLoading ?? this.isLoading,
      isApplying: isApplying ?? this.isApplying,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Backs the Subscription/Membership screen — current tier, centralized
/// pricing, and the affordability-program application flow. Founder
/// Scenario 27.
class SubscriptionController extends StateNotifier<SubscriptionState> {
  SubscriptionController({required SubscriptionsRepository repository})
    : _repository = repository,
      super(const SubscriptionState()) {
    refresh();
  }

  final SubscriptionsRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _repository.getMyStatus(),
        _repository.getPricing(),
      ]);
      state = SubscriptionState(
        status: results[0] as SubscriptionStatus,
        pricing: results[1] as List<PricingPoint>,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<bool> applyForEligibility({
    required AffordabilityProgram program,
    String? notes,
  }) async {
    state = state.copyWith(isApplying: true, clearError: true);
    try {
      final eligibility = await _repository.applyForEligibility(
        program: program,
        notes: notes,
      );
      state = state.copyWith(
        status: SubscriptionStatus(
          tier: state.status?.tier ?? PlanTier.free,
          eligibility: eligibility,
        ),
        isApplying: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(isApplying: false, error: error.toString());
      return false;
    }
  }
}

final subscriptionControllerProvider =
    StateNotifierProvider<SubscriptionController, SubscriptionState>((ref) {
      return SubscriptionController(
        repository: ref.watch(subscriptionsRepositoryProvider),
      );
    });
