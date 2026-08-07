import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/support_repository.dart';
import '../../domain/support_ticket.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(apiClient: ref.watch(apiClientProvider));
});

class SupportState {
  const SupportState({
    this.tickets = const [],
    this.isLoading = true,
    this.error,
  });

  final List<SupportTicket> tickets;
  final bool isLoading;
  final String? error;

  SupportState copyWith({
    List<SupportTicket>? tickets,
    bool? isLoading,
    String? error,
  }) {
    return SupportState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// The caller's own support tickets — Founder Scenario 27, free on
/// every tier.
class SupportController extends StateNotifier<SupportState> {
  SupportController({required SupportRepository repository})
    : _repository = repository,
      super(const SupportState()) {
    refresh();
  }

  final SupportRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final tickets = await _repository.listMine();
      state = SupportState(tickets: tickets, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }
}

final supportControllerProvider =
    StateNotifierProvider<SupportController, SupportState>((ref) {
      return SupportController(
        repository: ref.watch(supportRepositoryProvider),
      );
    });
