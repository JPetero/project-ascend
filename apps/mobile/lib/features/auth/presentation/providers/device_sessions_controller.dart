import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../domain/device_session.dart';
import 'auth_controller.dart';

enum DeviceSessionsStatus { loading, loaded, error }

class DeviceSessionsState {
  const DeviceSessionsState({
    this.status = DeviceSessionsStatus.loading,
    this.sessions = const [],
    this.errorMessage,
  });

  final DeviceSessionsStatus status;
  final List<DeviceSession> sessions;
  final String? errorMessage;

  DeviceSessionsState copyWith({
    DeviceSessionsStatus? status,
    List<DeviceSession>? sessions,
    String? errorMessage,
  }) {
    return DeviceSessionsState(
      status: status ?? this.status,
      sessions: sessions ?? this.sessions,
      errorMessage: errorMessage,
    );
  }
}

/// Drives the "Your devices" list (Build Session 10 Part 11) — every
/// device with an active session, and the actions to sign one (or every
/// other one) out.
class DeviceSessionsController extends StateNotifier<DeviceSessionsState> {
  DeviceSessionsController({
    required AuthRepository repository,
    required AuthController authController,
  }) : _repository = repository,
       _authController = authController,
       super(const DeviceSessionsState()) {
    load();
  }

  final AuthRepository _repository;
  final AuthController _authController;

  Future<void> load() async {
    state = state.copyWith(status: DeviceSessionsStatus.loading);
    try {
      final sessions = await _repository.getSessions();
      state = state.copyWith(
        status: DeviceSessionsStatus.loaded,
        sessions: sessions,
      );
    } catch (error) {
      state = state.copyWith(
        status: DeviceSessionsStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  /// Signs out one device. When [session] is this device, delegates to
  /// [AuthController.logout] so local tokens and offline data are cleared
  /// too, instead of leaving the app in a half-signed-out state. The
  /// caller is responsible for warning the user first when [session] is
  /// current — the server allows revoking your own session without
  /// complaint, so the confirmation has to live in the UI (see
  /// [DeviceSessionTile]).
  Future<void> revoke(DeviceSession session) async {
    if (session.current) {
      await _authController.logout();
      return;
    }
    await _repository.revokeSession(session.id);
    state = state.copyWith(
      sessions: state.sessions.where((s) => s.id != session.id).toList(),
    );
  }

  /// Signs out every device except this one. Returns how many were
  /// revoked so the caller can confirm what happened.
  Future<int> revokeOthers() async {
    final revokedCount = await _repository.revokeOtherSessions();
    state = state.copyWith(
      sessions: state.sessions.where((s) => s.current).toList(),
    );
    return revokedCount;
  }
}

final deviceSessionsControllerProvider =
    StateNotifierProvider.autoDispose<
      DeviceSessionsController,
      DeviceSessionsState
    >((ref) {
      return DeviceSessionsController(
        repository: ref.watch(authRepositoryProvider),
        authController: ref.watch(authControllerProvider.notifier),
      );
    });
