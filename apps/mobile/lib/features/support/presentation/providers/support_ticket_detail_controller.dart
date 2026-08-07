import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/support_repository.dart';
import '../../domain/support_ticket.dart';
import 'support_controller.dart';

class SupportTicketDetailState {
  const SupportTicketDetailState({
    this.ticket,
    this.isLoading = true,
    this.isReplying = false,
    this.error,
  });

  final SupportTicket? ticket;
  final bool isLoading;
  final bool isReplying;
  final String? error;

  SupportTicketDetailState copyWith({
    SupportTicket? ticket,
    bool? isLoading,
    bool? isReplying,
    String? error,
    bool clearError = false,
  }) {
    return SupportTicketDetailState(
      ticket: ticket ?? this.ticket,
      isLoading: isLoading ?? this.isLoading,
      isReplying: isReplying ?? this.isReplying,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SupportTicketDetailController
    extends StateNotifier<SupportTicketDetailState> {
  SupportTicketDetailController({
    required SupportRepository repository,
    required this.ticketId,
  }) : _repository = repository,
       super(const SupportTicketDetailState()) {
    load();
  }

  final SupportRepository _repository;
  final String ticketId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ticket = await _repository.getById(ticketId);
      state = SupportTicketDetailState(ticket: ticket, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<bool> addReply(String body) async {
    state = state.copyWith(isReplying: true, clearError: true);
    try {
      await _repository.addReply(ticketId, body);
      await load();
      return true;
    } catch (error) {
      state = state.copyWith(isReplying: false, error: error.toString());
      return false;
    }
  }
}

final supportTicketDetailControllerProvider = StateNotifierProvider.family
    .autoDispose<
      SupportTicketDetailController,
      SupportTicketDetailState,
      String
    >((ref, ticketId) {
      return SupportTicketDetailController(
        repository: ref.watch(supportRepositoryProvider),
        ticketId: ticketId,
      );
    });
